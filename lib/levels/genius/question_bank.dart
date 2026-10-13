import 'genius_models.dart';

/// Indeks list = step - 1. Tiap step diisi cukup banyak soal agar tidak habis.
const List<List<QuizItem>> geniusBank = [
  // Step 1 - Mudah (pengetahuan umum)
  [
    QuizItem('Siapa orang pertama yang menginjakkan kaki di Bulan?',
        'Neil Armstrong', ['Buzz Aldrin', 'Yuri Gagarin', 'Michael Collins']),
    QuizItem('Siapa yang menerbangkan pesawat bermotor berawak pertama pada tahun 1903?',
        'Wright bersaudara',
        ['Leonardo da Vinci', 'Thomas Edison', 'Alexander Graham Bell']),
    QuizItem('Apa ibu kota Jepang?', 'Tokyo', ['Kyoto', 'Osaka', 'Seoul']),
    QuizItem('Planet apa yang paling besar di tata surya?', 'Jupiter',
        ['Saturnus', 'Neptunus', 'Bumi']),
    QuizItem('Siapa pelukis lukisan Mona Lisa?', 'Leonardo da Vinci',
        ['Pablo Picasso', 'Vincent van Gogh', 'Michelangelo']),
    QuizItem('Apa hewan darat tercepat di dunia?', 'Citah',
        ['Singa', 'Kuda', 'Harimau']),
    QuizItem('Berapa jumlah benua menurut model yang paling umum diajarkan?',
        '7', ['5', '6', '8']),
    QuizItem('Pada suhu berapa air murni mendidih di permukaan laut?',
        '100°C', ['90°C', '110°C', '80°C']),
  ],
  // Step 2 - Sedang (sains dan sejarah)
  [
    QuizItem('Siapa yang merumuskan hukum gravitasi universal?',
        'Isaac Newton', ['Galileo Galilei', 'Albert Einstein', 'Johannes Kepler']),
    QuizItem('Gas apa yang paling banyak terkandung di atmosfer Bumi?',
        'Nitrogen', ['Oksigen', 'Karbon dioksida', 'Argon']),
    QuizItem('Siapa yang menemukan penisilin pada tahun 1928?',
        'Alexander Fleming', ['Louis Pasteur', 'Robert Koch', 'Edward Jenner']),
    QuizItem('Siapa manusia pertama yang mengorbit Bumi (1961)?',
        'Yuri Gagarin', ['Neil Armstrong', 'Alan Shepard', 'John Glenn']),
    QuizItem('Organ apa yang menghasilkan hormon insulin?', 'Pankreas',
        ['Hati', 'Ginjal', 'Lambung']),
    QuizItem('Siapa penulis novel "Laskar Pelangi"?', 'Andrea Hirata',
        ['Tere Liye', 'Pramoedya Ananta Toer', 'Habiburrahman El Shirazy']),
    QuizItem('Apa lambang kimia untuk emas?', 'Au', ['Ag', 'Go', 'Gd']),
    QuizItem('Pada tahun berapa Perang Dunia II berakhir?', '1945',
        ['1939', '1918', '1950']),
  ],
  // Step 3 - Sulit (pengetahuan khusus)
  [
    QuizItem(
        'Di ruang hampa, palu dan bulu dijatuhkan bersamaan. Mengapa keduanya jatuh dengan percepatan sama?',
        'Percepatan gravitasi tidak bergantung pada massa benda',
        [
          'Bulu menjadi lebih berat di ruang hampa',
          'Tidak ada gravitasi di ruang hampa',
          'Palu tertahan oleh hambatan udara',
        ]),
    QuizItem('Menurut relativitas umum Einstein, gravitasi adalah akibat dari...',
        'Lengkungan ruang-waktu oleh massa dan energi',
        [
          'Tarikan tak terlihat antar atom',
          'Medan listrik antar planet',
          'Putaran Bumi pada porosnya',
        ]),
    QuizItem('Berapa kecepatan cahaya di ruang hampa (kira-kira)?',
        '300.000 km/detik',
        ['30.000 km/detik', '150.000 km/detik', '3.000.000 km/detik']),
    QuizItem('Selain Francis Crick, siapa yang mengusulkan model heliks ganda DNA pada 1953?',
        'James Watson', ['Gregor Mendel', 'Charles Darwin', 'Louis Pasteur']),
    QuizItem('Organel sel apa yang berperan utama menghasilkan energi (ATP)?',
        'Mitokondria', ['Ribosom', 'Lisosom', 'Badan Golgi']),
    QuizItem('Siapa orang pertama yang meraih hadiah Nobel di dua bidang berbeda?',
        'Marie Curie', ['Linus Pauling', 'Albert Einstein', 'Niels Bohr']),
    QuizItem('Berapa percepatan gravitasi di permukaan Bumi (kira-kira)?',
        '9,8 m/s²', ['1,6 m/s²', '3,7 m/s²', '24,8 m/s²']),
    QuizItem('Siapa yang pertama kali mengamati bulan-bulan Jupiter dengan teleskop (1610)?',
        'Galileo Galilei',
        ['Isaac Newton', 'Nicolaus Copernicus', 'Tycho Brahe']),
  ],
];
