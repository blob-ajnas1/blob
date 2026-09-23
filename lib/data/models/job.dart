import 'enums.dart';

/// jobs table/collection — posted by landowners & buyers.
class Job {
  final String id;
  final String posterId;
  final String posterName;
  final UserRole posterRole;
  final String title;
  final String description;
  final JobType jobType; // single worker or group
  final int workersNeeded;
  final int wagePerWorkerPaise; // INR paise
  final String district;
  final DateTime workDate;
  final JobStatus status;
  final int postingFeePaise; // 0 for first two free posts, else 5000 (₹50)
  final DateTime createdAt;

  const Job({
    required this.id,
    required this.posterId,
    required this.posterName,
    required this.posterRole,
    required this.title,
    required this.description,
    required this.jobType,
    required this.workersNeeded,
    required this.wagePerWorkerPaise,
    required this.district,
    required this.workDate,
    required this.createdAt,
    this.status = JobStatus.open,
    this.postingFeePaise = 0,
  });

  int get totalWagePaise => wagePerWorkerPaise * workersNeeded;

  Job copyWith({JobStatus? status}) => Job(
    id: id,
    posterId: posterId,
    posterName: posterName,
    posterRole: posterRole,
    title: title,
    description: description,
    jobType: jobType,
    workersNeeded: workersNeeded,
    wagePerWorkerPaise: wagePerWorkerPaise,
    district: district,
    workDate: workDate,
    status: status ?? this.status,
    postingFeePaise: postingFeePaise,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'poster_id': posterId,
    'poster_name': posterName,
    'poster_role': posterRole.name,
    'title': title,
    'description': description,
    'job_type': jobType.name,
    'workers_needed': workersNeeded,
    'wage_per_worker_paise': wagePerWorkerPaise,
    'district': district,
    'work_date': workDate.toIso8601String(),
    'status': status.name,
    'posting_fee_paise': postingFeePaise,
    'created_at': createdAt.toIso8601String(),
  };

  factory Job.fromMap(Map<dynamic, dynamic> m) => Job(
    id: m['id'] as String? ?? '',
    posterId: m['poster_id'] as String? ?? '',
    posterName: m['poster_name'] as String? ?? '',
    posterRole: UserRoleX.fromId(m['poster_role'] as String? ?? 'landowner'),
    title: m['title'] as String? ?? '',
    description: m['description'] as String? ?? '',
    jobType: (m['job_type'] as String? ?? 'group') == 'single'
        ? JobType.single
        : JobType.group,
    workersNeeded: (m['workers_needed'] as num?)?.toInt() ?? 1,
    wagePerWorkerPaise: (m['wage_per_worker_paise'] as num?)?.toInt() ?? 0,
    district: m['district'] as String? ?? '',
    workDate:
        DateTime.tryParse(m['work_date'] as String? ?? '') ?? DateTime.now(),
    status: JobStatusX.fromId(m['status'] as String? ?? 'open'),
    postingFeePaise: (m['posting_fee_paise'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// job_applications table/collection — the two-sided marketplace link.
class JobApplication {
  final String id;
  final String jobId;
  final String laborerId;
  final String laborerName;
  final LaborerType laborerType;
  final int groupSize;
  final ApplicationStatus status;
  final DateTime createdAt;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.laborerId,
    required this.laborerName,
    required this.laborerType,
    required this.createdAt,
    this.groupSize = 1,
    this.status = ApplicationStatus.applied,
  });

  JobApplication copyWith({ApplicationStatus? status}) => JobApplication(
    id: id,
    jobId: jobId,
    laborerId: laborerId,
    laborerName: laborerName,
    laborerType: laborerType,
    groupSize: groupSize,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'job_id': jobId,
    'laborer_id': laborerId,
    'laborer_name': laborerName,
    'laborer_type': laborerType.name,
    'group_size': groupSize,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory JobApplication.fromMap(Map<dynamic, dynamic> m) => JobApplication(
    id: m['id'] as String? ?? '',
    jobId: m['job_id'] as String? ?? '',
    laborerId: m['laborer_id'] as String? ?? '',
    laborerName: m['laborer_name'] as String? ?? '',
    laborerType: LaborerTypeX.fromId(
      m['laborer_type'] as String? ?? 'singleWorker',
    ),
    groupSize: (m['group_size'] as num?)?.toInt() ?? 1,
    status: ApplicationStatusX.fromId(m['status'] as String? ?? 'applied'),
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
