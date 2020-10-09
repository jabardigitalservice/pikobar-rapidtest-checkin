

class Validations {
  
  static String kodeValidation(String val) {
   

    if (val.isEmpty) return 'Kode kegiatan harus diisi';

    // if (val.length < 4) return Dictionary.errorMinimumName;

    // if (val.length > 255) return Dictionary.errorMaximumName;

    // if (!regex.hasMatch(val)) return Dictionary.errorInvalidName;

    return null;
  }

   static String locationValidation(String val) {
   

    if (val.isEmpty) return 'Lokasi harus diisi';

    // if (val.length < 4) return Dictionary.errorMinimumName;

    // if (val.length > 255) return Dictionary.errorMaximumName;

    // if (!regex.hasMatch(val)) return Dictionary.errorInvalidName;

    return null;
  }

  static String kodeSampleValidation(String val) {
   

    if (val.isEmpty) return 'Kode sampel harus diisi';

    // if (val.length < 4) return Dictionary.errorMinimumName;

    // if (val.length > 255) return Dictionary.errorMaximumName;

    // if (!regex.hasMatch(val)) return Dictionary.errorInvalidName;

    return null;
  }

  static String usernameValidation(String val) {
   

    if (val.isEmpty) return 'Username harus diisi';

    // if (val.length < 4) return Dictionary.errorMinimumName;

    // if (val.length > 255) return Dictionary.errorMaximumName;

    // if (!regex.hasMatch(val)) return Dictionary.errorInvalidName;

    return null;
  }
  static String passwordValidation(String val) {
   

    if (val.isEmpty) return 'Password harus diisi';

    // if (val.length < 4) return Dictionary.errorMinimumName;

    // if (val.length > 255) return Dictionary.errorMaximumName;

    // if (!regex.hasMatch(val)) return Dictionary.errorInvalidName;

    return null;
  }
}
