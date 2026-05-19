use core_foundation::dictionary::CFDictionaryRef;
use serde::Serialize;
use std::{collections::HashMap, ffi::CStr, mem, ptr, time::Instant};

use crate::sources::{
  IOHIDSensors, IOReport, SMC, SocInfo, cfio_get_residencies, cfio_watts, libc_ram, libc_swap,
};

type WithError<T> = Result<T, Box<dyn std::error::Error>>;

// const CPU_FREQ_DICE_SUBG: &str = "CPU Complex Performance States";
const CPU_FREQ_CORE_SUBG: &str = "CPU Core Performance States";
const GPU_FREQ_DICE_SUBG: &str = "GPU Performance States";
const PROCESS_POWER_LIMIT: usize = 5;

// MARK: Structs

#[derive(Debug, Default, Serialize)]
pub struct TempMetrics {
  pub cpu_temp_avg: f32, // Celsius
  pub gpu_temp_avg: f32, // Celsius
}

#[derive(Debug, Default, Serialize)]
pub struct MemMetrics {
  pub ram_total: u64,  // bytes
  pub ram_usage: u64,  // bytes
  pub swap_total: u64, // bytes
  pub swap_usage: u64, // bytes
}

#[derive(Debug, Default, Serialize)]
pub struct Metrics {
  pub temp: TempMetrics,
  pub memory: MemMetrics,
  pub network: NetworkMetrics,
  pub ecpu_usage: (u32, f32), // freq, percent_from_max
  pub pcpu_usage: (u32, f32), // freq, percent_from_max
  pub cpu_usage_pct: f32,     // combined ecpu+pcpu usage, weighted by core count
  pub gpu_usage: (u32, f32),  // freq, percent_from_max
  pub cpu_power: f32,         // Watts
  pub gpu_power: f32,         // Watts
  pub ane_power: f32,         // Watts
  pub all_power: f32,         // Watts
  pub sys_power: f32,         // Watts
  pub ram_power: f32,         // Watts
  pub gpu_ram_power: f32,     // Watts
  pub process_power: Vec<ProcessPowerMetric>,
}

#[derive(Debug, Default, Serialize)]
pub struct NetworkMetrics {
  pub download_bytes_per_second: f32,
  pub upload_bytes_per_second: f32,
  pub received_bytes: u64,
  pub transmitted_bytes: u64,
}

#[derive(Debug, Default, Serialize)]
pub struct ProcessPowerMetric {
  pub pid: i32,
  pub name: String,
  pub estimated_power: f32, // Watts, from OS process energy when available; CPU-time allocation fallback
  pub cpu_usage_pct: f32,   // Activity Monitor style, where one full core is 100%
}

#[derive(Clone, Copy, Debug)]
pub struct SamplerOptions {
  pub process_power: bool,
  pub io_report_samples: usize,
}

impl Default for SamplerOptions {
  fn default() -> Self {
    Self { process_power: true, io_report_samples: 4 }
  }
}

#[derive(Clone, Debug)]
struct ProcessSample {
  start_time: u64,
  cpu_time_ns: u64,
  energy_nj: Option<u64>,
}

#[derive(Default)]
struct ProcessPowerSampler {
  previous: HashMap<i32, ProcessSample>,
  previous_time: Option<Instant>,
}

struct ProcessDelta {
  pid: i32,
  cpu_time_delta_ns: u64,
  energy_delta_nj: u64,
  cpu_usage_pct: f32,
}

#[repr(C)]
#[derive(Clone, Copy, Debug, Default)]
struct ProcessRusageInfoV6 {
  ri_uuid: [u8; 16],
  ri_user_time: u64,
  ri_system_time: u64,
  ri_pkg_idle_wkups: u64,
  ri_interrupt_wkups: u64,
  ri_pageins: u64,
  ri_wired_size: u64,
  ri_resident_size: u64,
  ri_phys_footprint: u64,
  ri_proc_start_abstime: u64,
  ri_proc_exit_abstime: u64,
  ri_child_user_time: u64,
  ri_child_system_time: u64,
  ri_child_pkg_idle_wkups: u64,
  ri_child_interrupt_wkups: u64,
  ri_child_pageins: u64,
  ri_child_elapsed_abstime: u64,
  ri_diskio_bytesread: u64,
  ri_diskio_byteswritten: u64,
  ri_cpu_time_qos_default: u64,
  ri_cpu_time_qos_maintenance: u64,
  ri_cpu_time_qos_background: u64,
  ri_cpu_time_qos_utility: u64,
  ri_cpu_time_qos_legacy: u64,
  ri_cpu_time_qos_user_initiated: u64,
  ri_cpu_time_qos_user_interactive: u64,
  ri_billed_system_time: u64,
  ri_serviced_system_time: u64,
  ri_logical_writes: u64,
  ri_lifetime_max_phys_footprint: u64,
  ri_instructions: u64,
  ri_cycles: u64,
  ri_billed_energy: u64,
  ri_serviced_energy: u64,
  ri_interval_max_phys_footprint: u64,
  ri_runnable_time: u64,
  ri_flags: u64,
  ri_user_ptime: u64,
  ri_system_ptime: u64,
  ri_pinstructions: u64,
  ri_pcycles: u64,
  ri_energy_nj: u64,
  ri_penergy_nj: u64,
  ri_secure_time_in_system: u64,
  ri_secure_ptime_in_system: u64,
  ri_neural_footprint: u64,
  ri_lifetime_max_neural_footprint: u64,
  ri_interval_max_neural_footprint: u64,
  ri_reserved: [u64; 9],
}

#[derive(Clone, Debug, Default)]
struct InterfaceCounters {
  received_bytes: u64,
  transmitted_bytes: u64,
}

#[derive(Default)]
struct NetworkSampler {
  previous: HashMap<String, InterfaceCounters>,
  previous_time: Option<Instant>,
}

// MARK: Helpers

pub fn zero_div<T: core::ops::Div<Output = T> + Default + PartialEq>(a: T, b: T) -> T {
  let zero: T = Default::default();
  if b == zero { zero } else { a / b }
}

fn is_valid_temp(val: f32) -> bool {
  val > 0.0 && val <= 150.0
}

fn calc_freq(item: CFDictionaryRef, freqs: &[u32]) -> (u32, f32) {
  let items = cfio_get_residencies(item); // (ns, freq)
  let (len1, len2) = (items.len(), freqs.len());
  assert!(len1 > len2, "cacl_freq invalid data: {} vs {}", len1, len2); // todo?

  // IDLE / DOWN for CPU; OFF for GPU; DOWN only on M2?/M3 Max Chips
  let offset = items.iter().position(|x| x.0 != "IDLE" && x.0 != "DOWN" && x.0 != "OFF").unwrap();

  let usage = items.iter().map(|x| x.1 as f64).skip(offset).sum::<f64>();
  let total = items.iter().map(|x| x.1 as f64).sum::<f64>();
  let count = freqs.len();

  let mut avg_freq = 0f64;
  for i in 0..count {
    let percent = zero_div(items[i + offset].1 as _, usage);
    avg_freq += percent * freqs[i] as f64;
  }

  let usage_ratio = zero_div(usage, total);
  let min_freq = *freqs.first().unwrap() as f64;
  let max_freq = *freqs.last().unwrap() as f64;
  let from_max = (avg_freq.max(min_freq) * usage_ratio) / max_freq;

  (avg_freq as u32, from_max as f32)
}

fn calc_freq_final(items: &[(u32, f32)], freqs: &[u32]) -> (u32, f32) {
  let avg_freq = zero_div(items.iter().map(|x| x.0 as f32).sum(), items.len() as f32);
  let avg_perc = zero_div(items.iter().map(|x| x.1).sum(), items.len() as f32);
  let min_freq = *freqs.first().unwrap() as f32;

  (avg_freq.max(min_freq) as u32, avg_perc)
}

impl NetworkSampler {
  fn metrics(&mut self) -> NetworkMetrics {
    let now = Instant::now();
    let current = sample_network_interfaces();

    let total = current.values().fold(InterfaceCounters::default(), |mut acc, counters| {
      acc.received_bytes = acc.received_bytes.saturating_add(counters.received_bytes);
      acc.transmitted_bytes = acc.transmitted_bytes.saturating_add(counters.transmitted_bytes);
      acc
    });

    let elapsed_seconds = self
      .previous_time
      .map(|previous_time| now.duration_since(previous_time).as_secs_f32())
      .unwrap_or_default();

    let mut received_delta = 0u64;
    let mut transmitted_delta = 0u64;

    if elapsed_seconds > 0.0 {
      for (name, counters) in &current {
        let Some(previous_counters) = self.previous.get(name) else {
          continue;
        };

        received_delta = received_delta.saturating_add(counter_delta(
          counters.received_bytes,
          previous_counters.received_bytes,
          u32::MAX as u64,
        ));
        transmitted_delta = transmitted_delta.saturating_add(counter_delta(
          counters.transmitted_bytes,
          previous_counters.transmitted_bytes,
          u32::MAX as u64,
        ));
      }
    }

    self.previous = current;
    self.previous_time = Some(now);

    NetworkMetrics {
      download_bytes_per_second: zero_div(received_delta as f32, elapsed_seconds),
      upload_bytes_per_second: zero_div(transmitted_delta as f32, elapsed_seconds),
      received_bytes: total.received_bytes,
      transmitted_bytes: total.transmitted_bytes,
    }
  }
}

fn counter_delta(current: u64, previous: u64, max_counter_value: u64) -> u64 {
  if current >= previous {
    current - previous
  } else {
    current.saturating_add(max_counter_value.saturating_add(1).saturating_sub(previous))
  }
}

fn sample_network_interfaces() -> HashMap<String, InterfaceCounters> {
  let mut addrs: *mut libc::ifaddrs = ptr::null_mut();
  if unsafe { libc::getifaddrs(&mut addrs) } != 0 {
    return HashMap::new();
  }

  let mut interfaces = HashMap::new();
  let mut current = addrs;

  while !current.is_null() {
    let ifaddr = unsafe { &*current };

    if is_network_counter_interface(ifaddr) {
      let name = unsafe { CStr::from_ptr(ifaddr.ifa_name) }.to_string_lossy().into_owned();
      let data = unsafe { &*(ifaddr.ifa_data as *const libc::if_data) };
      interfaces.insert(
        name,
        InterfaceCounters {
          received_bytes: data.ifi_ibytes as u64,
          transmitted_bytes: data.ifi_obytes as u64,
        },
      );
    }

    current = ifaddr.ifa_next;
  }

  unsafe { libc::freeifaddrs(addrs) };
  interfaces
}

fn is_network_counter_interface(ifaddr: &libc::ifaddrs) -> bool {
  if ifaddr.ifa_addr.is_null() || ifaddr.ifa_data.is_null() || ifaddr.ifa_name.is_null() {
    return false;
  }

  let flags = ifaddr.ifa_flags as i32;
  if flags & libc::IFF_UP == 0 || flags & libc::IFF_RUNNING == 0 || flags & libc::IFF_LOOPBACK != 0
  {
    return false;
  }

  unsafe { (*ifaddr.ifa_addr).sa_family as i32 == libc::AF_LINK }
}

impl ProcessPowerSampler {
  fn top_processes(&mut self, cpu_power_watts: f32) -> Vec<ProcessPowerMetric> {
    let now = Instant::now();
    let current = sample_processes();
    let elapsed_ns = self
      .previous_time
      .map(|previous_time| now.duration_since(previous_time).as_nanos() as u64)
      .unwrap_or_default();

    let mut deltas: Vec<ProcessDelta> = Vec::new();

    if elapsed_ns > 0 {
      for (pid, current_sample) in &current {
        let Some(previous_sample) = self.previous.get(pid) else {
          continue;
        };

        if previous_sample.start_time != current_sample.start_time {
          continue;
        }

        let cpu_time_delta_ns =
          current_sample.cpu_time_ns.saturating_sub(previous_sample.cpu_time_ns);
        let energy_delta_nj = match (current_sample.energy_nj, previous_sample.energy_nj) {
          (Some(current_energy), Some(previous_energy)) => {
            current_energy.saturating_sub(previous_energy)
          }
          _ => 0,
        };

        if cpu_time_delta_ns == 0 && energy_delta_nj == 0 {
          continue;
        }

        let cpu_usage_pct = (cpu_time_delta_ns as f64 / elapsed_ns as f64 * 100.0) as f32;
        deltas.push(ProcessDelta { pid: *pid, cpu_time_delta_ns, energy_delta_nj, cpu_usage_pct });
      }
    }

    self.previous = current;
    self.previous_time = Some(now);

    let total_energy_delta_nj: u64 = deltas.iter().map(|delta| delta.energy_delta_nj).sum();
    if total_energy_delta_nj > 0 {
      deltas.sort_by(|a, b| b.energy_delta_nj.cmp(&a.energy_delta_nj));
      deltas.truncate(PROCESS_POWER_LIMIT);

      return deltas
        .into_iter()
        .map(|delta| ProcessPowerMetric {
          pid: delta.pid,
          name: process_name(delta.pid),
          estimated_power: delta.energy_delta_nj as f32 / elapsed_ns as f32,
          cpu_usage_pct: delta.cpu_usage_pct,
        })
        .collect();
    }

    let total_cpu_time_delta_ns: u64 = deltas.iter().map(|delta| delta.cpu_time_delta_ns).sum();
    if total_cpu_time_delta_ns == 0 || cpu_power_watts <= 0.0 {
      return Vec::new();
    }
    deltas.sort_by(|a, b| b.cpu_time_delta_ns.cmp(&a.cpu_time_delta_ns));
    deltas.truncate(PROCESS_POWER_LIMIT);

    deltas
      .into_iter()
      .map(|delta| ProcessPowerMetric {
        pid: delta.pid,
        name: process_name(delta.pid),
        estimated_power: cpu_power_watts * delta.cpu_time_delta_ns as f32
          / total_cpu_time_delta_ns as f32,
        cpu_usage_pct: delta.cpu_usage_pct,
      })
      .collect()
  }
}

fn sample_processes() -> HashMap<i32, ProcessSample> {
  let pids = list_pids();
  let mut samples = HashMap::with_capacity(pids.len());

  // Exact ranking needs all visible PIDs: libproc does not expose a pre-sorted
  // "top by energy" list, and the score is a delta from the previous sample.
  // Keep the full counter pass, but defer process-name lookup until after rank.
  for pid in pids {
    if let Some(sample) = sample_process(pid) {
      samples.insert(pid, sample);
    }
  }

  samples
}

fn list_pids() -> Vec<i32> {
  const PROC_ALL_PIDS: u32 = 1;
  let pid_size = mem::size_of::<i32>();
  let initial_bytes = unsafe { libc::proc_listpids(PROC_ALL_PIDS, 0, ptr::null_mut(), 0) };

  if initial_bytes <= 0 {
    return Vec::new();
  }

  let mut pids = vec![0i32; initial_bytes as usize / pid_size + 256];
  let byte_count = unsafe {
    libc::proc_listpids(
      PROC_ALL_PIDS,
      0,
      pids.as_mut_ptr() as *mut libc::c_void,
      (pids.len() * pid_size) as libc::c_int,
    )
  };

  if byte_count <= 0 {
    return Vec::new();
  }

  let pid_count = byte_count as usize / pid_size;
  pids.truncate(pid_count);
  pids.into_iter().filter(|pid| *pid > 0).collect()
}

fn sample_process(pid: i32) -> Option<ProcessSample> {
  if let Some(sample) = sample_process_v6(pid) {
    return Some(sample);
  }

  let mut usage = mem::MaybeUninit::<libc::rusage_info_v4>::zeroed();
  let result = unsafe {
    libc::proc_pid_rusage(pid, libc::RUSAGE_INFO_V4, usage.as_mut_ptr() as *mut libc::rusage_info_t)
  };

  if result != 0 {
    return None;
  }

  let usage = unsafe { usage.assume_init() };
  Some(ProcessSample {
    start_time: usage.ri_proc_start_abstime,
    cpu_time_ns: usage.ri_user_time.saturating_add(usage.ri_system_time),
    energy_nj: None,
  })
}

fn sample_process_v6(pid: i32) -> Option<ProcessSample> {
  const RUSAGE_INFO_V6: libc::c_int = 6;

  let mut usage = mem::MaybeUninit::<ProcessRusageInfoV6>::zeroed();
  let result = unsafe {
    libc::proc_pid_rusage(pid, RUSAGE_INFO_V6, usage.as_mut_ptr() as *mut libc::rusage_info_t)
  };

  if result != 0 {
    return None;
  }

  let usage = unsafe { usage.assume_init() };
  let cpu_time_ns = usage
    .ri_user_ptime
    .saturating_add(usage.ri_system_ptime)
    .max(usage.ri_user_time.saturating_add(usage.ri_system_time));
  let energy_nj = match usage.ri_energy_nj {
    energy if energy > 0 => Some(energy),
    _ if usage.ri_penergy_nj > 0 => Some(usage.ri_penergy_nj),
    _ => None,
  };

  Some(ProcessSample { start_time: usage.ri_proc_start_abstime, cpu_time_ns, energy_nj })
}

fn process_name(pid: i32) -> String {
  let mut buffer = [0i8; 256];
  let length =
    unsafe { libc::proc_name(pid, buffer.as_mut_ptr() as *mut libc::c_void, buffer.len() as u32) };

  if length > 0 {
    let name = unsafe { CStr::from_ptr(buffer.as_ptr()) }.to_string_lossy().into_owned();
    if !name.is_empty() {
      return name;
    }
  }

  format!("pid {pid}")
}

fn init_smc() -> WithError<(SMC, Vec<String>, Vec<String>)> {
  let mut smc = SMC::new()?;
  const FLOAT_TYPE: u32 = 1718383648; // FourCC: "flt "

  let mut cpu_sensors = Vec::new();
  let mut gpu_sensors = Vec::new();

  let names = smc.read_all_keys().unwrap_or(vec![]);
  for name in &names {
    let key = match smc.read_key_info(name) {
      Ok(key) => key,
      Err(_) => continue,
    };

    if key.data_size != 4 || key.data_type != FLOAT_TYPE {
      continue;
    }

    let _ = match smc.read_val(name) {
      Ok(val) => val,
      Err(_) => continue,
    };

    // Unfortunately, it is not known which keys are responsible for what.
    // Basically in the code that can be found publicly "Tp" is used for CPU and "Tg" for GPU.

    match name {
      // "Tp" – performance cores, "Te" – efficiency cores, "Ts" – super cores (M5+)
      name if name.starts_with("Tp") || name.starts_with("Te") || name.starts_with("Ts") => {
        cpu_sensors.push(name.clone())
      }
      name if name.starts_with("Tg") => gpu_sensors.push(name.clone()),
      _ => (),
    }
  }

  // println!("{} {}", cpu_sensors.len(), gpu_sensors.len());
  Ok((smc, cpu_sensors, gpu_sensors))
}

// MARK: Sampler

pub struct Sampler {
  soc: SocInfo,
  ior: IOReport,
  hid: IOHIDSensors,
  smc: SMC,
  smc_cpu_keys: Vec<String>,
  smc_gpu_keys: Vec<String>,
  network: NetworkSampler,
  process_power: ProcessPowerSampler,
}

impl Sampler {
  pub fn new() -> WithError<Self> {
    let channels = vec![
      ("Energy Model", None), // cpu/gpu/ane power
      // ("CPU Stats", Some(CPU_FREQ_DICE_SUBG)), // cpu freq by cluster
      ("CPU Stats", Some(CPU_FREQ_CORE_SUBG)), // cpu freq per core
      ("GPU Stats", Some(GPU_FREQ_DICE_SUBG)), // gpu freq
    ];

    let soc = SocInfo::new()?;
    let ior = IOReport::new(channels)?;
    let hid = IOHIDSensors::new()?;
    let (smc, smc_cpu_keys, smc_gpu_keys) = init_smc()?;

    Ok(Sampler {
      soc,
      ior,
      hid,
      smc,
      smc_cpu_keys,
      smc_gpu_keys,
      network: NetworkSampler::default(),
      process_power: ProcessPowerSampler::default(),
    })
  }

  fn get_temp_smc(&mut self) -> WithError<TempMetrics> {
    let mut cpu_metrics = Vec::new();
    for sensor in &self.smc_cpu_keys {
      let val = self.smc.read_val(sensor)?;
      let val = f32::from_le_bytes(val.data[0..4].try_into().unwrap());
      if is_valid_temp(val) {
        cpu_metrics.push(val);
      }
    }

    let mut gpu_metrics = Vec::new();
    for sensor in &self.smc_gpu_keys {
      let val = self.smc.read_val(sensor)?;
      let val = f32::from_le_bytes(val.data[0..4].try_into().unwrap());
      if is_valid_temp(val) {
        gpu_metrics.push(val);
      }
    }

    let cpu_temp_avg = zero_div(cpu_metrics.iter().sum::<f32>(), cpu_metrics.len() as f32);
    let gpu_temp_avg = zero_div(gpu_metrics.iter().sum::<f32>(), gpu_metrics.len() as f32);

    Ok(TempMetrics { cpu_temp_avg, gpu_temp_avg })
  }

  fn get_temp_hid(&mut self) -> WithError<TempMetrics> {
    let metrics = self.hid.get_metrics();

    let mut cpu_values = Vec::new();
    let mut gpu_values = Vec::new();

    for (name, value) in &metrics {
      if name.starts_with("pACC MTR Temp Sensor") || name.starts_with("eACC MTR Temp Sensor") {
        // println!("{}: {}", name, value);
        if is_valid_temp(*value) {
          cpu_values.push(*value);
        }
        continue;
      }

      if name.starts_with("GPU MTR Temp Sensor") {
        // println!("{}: {}", name, value);
        if is_valid_temp(*value) {
          gpu_values.push(*value);
        }
        continue;
      }
    }

    let cpu_temp_avg = zero_div(cpu_values.iter().sum(), cpu_values.len() as f32);
    let gpu_temp_avg = zero_div(gpu_values.iter().sum(), gpu_values.len() as f32);

    Ok(TempMetrics { cpu_temp_avg, gpu_temp_avg })
  }

  fn get_temp(&mut self) -> WithError<TempMetrics> {
    // HID for M1, SMC for M2/M3
    // UPD: Looks like HID/SMC related to OS version, not to the chip (SMC available from macOS 14)
    match !self.smc_cpu_keys.is_empty() {
      true => self.get_temp_smc(),
      false => self.get_temp_hid(),
    }
  }

  fn get_mem(&mut self) -> WithError<MemMetrics> {
    let (ram_usage, ram_total) = libc_ram()?;
    let (swap_usage, swap_total) = libc_swap()?;
    Ok(MemMetrics { ram_total, ram_usage, swap_total, swap_usage })
  }

  fn get_sys_power(&mut self) -> WithError<f32> {
    let val = self.smc.read_val("PSTR")?;
    let val = f32::from_le_bytes(val.data.clone().try_into().unwrap());
    Ok(val)
  }

  pub fn get_metrics(&mut self, duration: u32) -> WithError<Metrics> {
    self.get_metrics_with_options(duration, SamplerOptions::default())
  }

  pub fn get_metrics_with_options(
    &mut self,
    duration: u32,
    options: SamplerOptions,
  ) -> WithError<Metrics> {
    let measures = options.io_report_samples.clamp(1, 32);
    let mut results: Vec<Metrics> = Vec::with_capacity(measures);

    // CPU Stats channel naming by chip family (see: https://github.com/vladkens/macmon/issues/47)
    //   M1-M4:  ECPU* = efficiency cores (lower tier)
    //           PCPU* = performance cores (top tier)
    //   M5:     Apple renamed ECPU → MCPU in IOReport and introduced a third core tier.
    //           Three-tier architecture (sysctl hw.perflevel{N}.name):
    //             perflevel0 = Super       (top tier,    ex-P, PCPU* in IOReport)
    //             perflevel1 = Performance (mid tier,    Pro/Max only, MCPU* in IOReport)
    //             perflevel2 = Efficiency  (base M5 only, absent on Pro/Max)
    //           M5 Max example: 6 Super + 12 Performance + 0 Efficiency = 18 total.
    //   Ultra:  Any-generation Ultra chips prefix channels with "DIE_N_"
    //           (e.g. "DIE_0_ECPU0"), so use contains() not starts_with() — same
    //           pattern as Energy Model's "DIE_{}_CPU Energy".

    // do several samples to smooth metrics
    // see: https://github.com/vladkens/macmon/issues/10
    for (sample, dt) in self.ior.get_samples(duration as u64, measures) {
      let mut ecpu_usages = Vec::new();
      let mut pcpu_usages = Vec::new();
      let mut rs = Metrics::default();

      for x in sample {
        if x.group == "CPU Stats" && x.subgroup == CPU_FREQ_CORE_SUBG {
          if x.channel.contains("PCPU") {
            pcpu_usages.push(calc_freq(x.item, &self.soc.pcpu_freqs));
            continue;
          }

          if x.channel.contains("ECPU") || x.channel.contains("MCPU") {
            ecpu_usages.push(calc_freq(x.item, &self.soc.ecpu_freqs));
            continue;
          }
        }

        if x.group == "GPU Stats" && x.subgroup == GPU_FREQ_DICE_SUBG {
          match x.channel.as_str() {
            "GPUPH" => rs.gpu_usage = calc_freq(x.item, &self.soc.gpu_freqs[1..]),
            _ => {}
          }
        }

        if x.group == "Energy Model" {
          match x.channel.as_str() {
            "GPU Energy" => rs.gpu_power += cfio_watts(x.item, &x.unit, dt)?,
            // "CPU Energy" for Basic / Max, "DIE_{}_CPU Energy" for Ultra
            c if c.ends_with("CPU Energy") => rs.cpu_power += cfio_watts(x.item, &x.unit, dt)?,
            // same pattern next keys: "ANE" for Basic, "ANE0" for Max, "ANE0_{}" for Ultra
            c if c.starts_with("ANE") => rs.ane_power += cfio_watts(x.item, &x.unit, dt)?,
            c if c.starts_with("DRAM") => rs.ram_power += cfio_watts(x.item, &x.unit, dt)?,
            c if c.starts_with("GPU SRAM") => rs.gpu_ram_power += cfio_watts(x.item, &x.unit, dt)?,
            _ => {}
          }
        }
      }

      // Filter dead/disabled cores (e.g. M5 Max MCPU0 cluster is all-DOWN)
      ecpu_usages.retain(|&(_, pct)| pct > 0.0);
      rs.ecpu_usage = calc_freq_final(&ecpu_usages, &self.soc.ecpu_freqs);
      rs.pcpu_usage = calc_freq_final(&pcpu_usages, &self.soc.pcpu_freqs);
      results.push(rs);
    }

    let ecores = self.soc.ecpu_cores as f32;
    let pcores = self.soc.pcpu_cores as f32;
    let tcores = ecores + pcores;

    let mut rs = Metrics::default();
    rs.ecpu_usage.0 = zero_div(results.iter().map(|x| x.ecpu_usage.0).sum(), measures as _);
    rs.ecpu_usage.1 = zero_div(results.iter().map(|x| x.ecpu_usage.1).sum(), measures as _);
    rs.pcpu_usage.0 = zero_div(results.iter().map(|x| x.pcpu_usage.0).sum(), measures as _);
    rs.pcpu_usage.1 = zero_div(results.iter().map(|x| x.pcpu_usage.1).sum(), measures as _);
    rs.cpu_usage_pct = zero_div(rs.ecpu_usage.1 * ecores + rs.pcpu_usage.1 * pcores, tcores);
    rs.gpu_usage.0 = zero_div(results.iter().map(|x| x.gpu_usage.0).sum(), measures as _);
    rs.gpu_usage.1 = zero_div(results.iter().map(|x| x.gpu_usage.1).sum(), measures as _);
    rs.cpu_power = zero_div(results.iter().map(|x| x.cpu_power).sum(), measures as _);
    rs.gpu_power = zero_div(results.iter().map(|x| x.gpu_power).sum(), measures as _);
    rs.ane_power = zero_div(results.iter().map(|x| x.ane_power).sum(), measures as _);
    rs.ram_power = zero_div(results.iter().map(|x| x.ram_power).sum(), measures as _);
    rs.gpu_ram_power = zero_div(results.iter().map(|x| x.gpu_ram_power).sum(), measures as _);
    rs.all_power = rs.cpu_power + rs.gpu_power + rs.ane_power;
    if options.process_power {
      rs.process_power = self.process_power.top_processes(rs.cpu_power);
    }

    rs.memory = self.get_mem()?;
    rs.network = self.network.metrics();
    rs.temp = self.get_temp()?;

    rs.sys_power = match self.get_sys_power() {
      Ok(val) => val.max(rs.all_power),
      Err(_) => 0.0,
    };

    Ok(rs)
  }

  /// Getter for the `soc` field
  pub fn get_soc_info(&self) -> &SocInfo {
    &self.soc
  }
}

#[cfg(test)]
mod tests {
  use super::counter_delta;

  #[test]
  fn ultra_cpu_channel_matching() {
    // On Ultra chips (M1/M2/M3 Ultra) IOReport CPU Stats channels are prefixed "DIE_N_".
    // These should be recognised; they were with contains() in v0.6.1 but broke when
    // ff5f058 changed to starts_with().
    let cases = [
      ("DIE_0_ECPU0", "ecpu"),
      ("DIE_1_ECPU0", "ecpu"),
      ("DIE_0_PCPU0", "pcpu"),
      ("DIE_1_PCPU0", "pcpu"),
      // Standard (non-Ultra) channels must still work
      ("ECPU0", "ecpu"),
      ("PCPU0", "pcpu"),
      ("MCPU0", "ecpu"), // M5+ performance cores map to ecpu slot
    ];
    for (ch, expected) in cases {
      let matched = if ch.contains("PCPU") {
        "pcpu"
      } else if ch.contains("ECPU") || ch.contains("MCPU") {
        "ecpu"
      } else {
        "none"
      };
      assert_eq!(matched, expected, "channel {ch}");
    }
  }

  #[test]
  fn network_counter_delta_handles_wraparound() {
    assert_eq!(counter_delta(150, 100, u32::MAX as u64), 50);
    assert_eq!(counter_delta(24, u32::MAX as u64 - 5, u32::MAX as u64), 30);
  }
}
