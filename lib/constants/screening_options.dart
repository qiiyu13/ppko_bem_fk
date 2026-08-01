/// Dropdown options for the health variables (demografi, antropometri,
/// perilaku). Keys are what the backend stores (validated against
/// backend/src/utils/healthOptions.js — keep in sync); labels are what the
/// user sees.
library;

typedef OptionItem = ({String key, String label});

class ScreeningOptions {
  ScreeningOptions._();

  static const education = <OptionItem>[
    (key: 'tidak_sekolah', label: 'Tidak tamat sekolah'),
    (key: 'sd', label: 'Tamat SD'),
    (key: 'smp', label: 'Tamat SMP'),
    (key: 'sma', label: 'Tamat SMA'),
    (key: 'diploma', label: 'Tamat D1/D2/D3'),
    (key: 'pt', label: 'Tamat Perguruan Tinggi'),
  ];

  static const occupation = <OptionItem>[
    (key: 'tidak_bekerja', label: 'Tidak bekerja'),
    (key: 'sekolah', label: 'Sekolah'),
    (key: 'pns_tni_polri', label: 'PNS/ TNI/ Polri/ BUMN/ BUMD'),
    (key: 'pegawai_swasta', label: 'Pegawai swasta'),
    (key: 'wiraswasta', label: 'Wiraswasta'),
    (key: 'petani', label: 'Petani/ buruh tani'),
    (key: 'pedagang', label: 'Pedagang'),
    (key: 'lainnya', label: 'Lainnya'),
  ];

  static const maritalStatus = <OptionItem>[
    (key: 'menikah', label: 'Menikah'),
    (key: 'belum_menikah', label: 'Belum menikah'),
    (key: 'cerai_hidup', label: 'Cerai hidup'),
    (key: 'cerai_mati', label: 'Cerai mati'),
  ];

  static const familyDiseaseHistory = <OptionItem>[
    (key: 'ada', label: 'Ada'),
    (key: 'tidak', label: 'Tidak ada'),
  ];

  static const smokingStatus = <OptionItem>[
    (key: 'bukan_perokok', label: 'Bukan perokok'),
    (key: 'serumah_perokok', label: 'Bukan perokok, tapi serumah ada perokok'),
    (key: 'mantan_perokok', label: 'Mantan perokok'),
    (key: 'perokok_aktif', label: 'Perokok aktif'),
  ];

  static const physicalActivity = <OptionItem>[
    (key: 'rendah', label: 'Rendah (jalan kaki, 1–2x/minggu)'),
    (key: 'sedang', label: 'Sedang (jalan kaki, 3–5x/minggu)'),
    (key: 'tinggi', label: 'Tinggi (jogging, 3–5x/minggu)'),
  ];

  static const fruitConsumption = <OptionItem>[
    (key: 'rendah', label: 'Kurang dari 5 porsi/hari'),
    (key: 'cukup', label: '5 porsi/hari atau lebih'),
  ];

  static const vegetableConsumption = fruitConsumption;

  static const sweetFoodConsumption = <OptionItem>[
    (key: 'sering', label: 'Sering (1–6x/minggu)'),
    (key: 'jarang', label: 'Jarang (≤3x/bulan atau tidak pernah)'),
  ];

  static const sweetDrinkConsumption = sweetFoodConsumption;
  static const fattyFoodConsumption = sweetFoodConsumption;
  static const fastFoodConsumption = sweetFoodConsumption;

  static const medicationRoutine = <OptionItem>[
    (key: 'sehat', label: 'Tidak, karena sehat'),
    (key: 'tidak_rutin', label: 'Tidak rutin'),
    (key: 'rutin', label: 'Rutin'),
  ];

  /// Label for a stored key, or '-' when unset/unknown (old rows, partial data).
  static String labelFor(List<OptionItem> options, String? key) {
    if (key == null) return '-';
    for (final o in options) {
      if (o.key == key) return o.label;
    }
    return key;
  }
}
