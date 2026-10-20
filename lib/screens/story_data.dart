class StoryPanel {
  const StoryPanel({required this.image, required this.caption});

  final String image;
  final String caption;
}

/// Urutan cerita: 1 (atas) -> 2 (kanan atas) -> 3 (kanan bawah) -> 4 (kiri besar).
/// Ganti gambar dengan menimpa file panel_*.png; ubah kalimat di sini.
const storyPanels = <StoryPanel>[
  StoryPanel(
    image: 'assets/images/story/panel_1.png',
    caption: 'Dunia ada di tangan para juara...',
  ),
  StoryPanel(
    image: 'assets/images/story/panel_2.png',
    caption: 'Tiap bidang punya masternya sendiri.',
  ),
  StoryPanel(
    image: 'assets/images/story/panel_3.png',
    caption: 'Tapi hanya satu yang jadi juara utama.',
  ),
  StoryPanel(
    image: 'assets/images/story/panel_4.png',
    caption: 'Aku akan mengalahkan mereka semua!',
  ),
];
