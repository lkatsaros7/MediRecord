class Patient {
  final String patientId;
  final String name;
  final String surname;
  final String? dateOfBirth;
  final String? mobile;
  final String? phone;
  final String? email;
  final String? address;
  final String? healthInformation;
  final String? allergies;
  final String? medication;
  final String? medicalHistory;
  final String? emergencyContact;

  const Patient({
    required this.patientId,
    required this.name,
    required this.surname,
    this.dateOfBirth,
    this.mobile,
    this.phone,
    this.email,
    this.address,
    this.healthInformation,
    this.allergies,
    this.medication,
    this.medicalHistory,
    this.emergencyContact,
  });

  String get fullName => '$name $surname';

  Patient copyWith({
    String? patientId,
    String? name,
    String? surname,
    String? dateOfBirth,
    String? mobile,
    String? phone,
    String? email,
    String? address,
    String? healthInformation,
    String? allergies,
    String? medication,
    String? medicalHistory,
    String? emergencyContact,
  }) =>
      Patient(
        patientId: patientId ?? this.patientId,
        name: name ?? this.name,
        surname: surname ?? this.surname,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        mobile: mobile ?? this.mobile,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        healthInformation: healthInformation ?? this.healthInformation,
        allergies: allergies ?? this.allergies,
        medication: medication ?? this.medication,
        medicalHistory: medicalHistory ?? this.medicalHistory,
        emergencyContact: emergencyContact ?? this.emergencyContact,
      );
}
