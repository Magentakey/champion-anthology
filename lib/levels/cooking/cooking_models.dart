import 'dart:math';

/// Tiga stasiun masak. Tiap bahan hanya cocok di satu stasiun.
enum Station {
  chop('Talenan', 'iris'),
  boil('Panci', 'rebus'),
  fry('Wajan', 'goreng');

  const Station(this.label, this.verb);

  /// Nama alat di layar.
  final String label;

  /// Cara masak (kata kerja dasar), dipakai di kartu pesanan.
  final String verb;
}

class Ingredient {
  const Ingredient(this.id, this.name, this.station);

  final String id;
  final String name;
  final Station station;

  String get imageAsset => 'assets/images/cooking/ing_$id.png';
}

/// Semua bahan. Gambar: `assets/images/cooking/ing_(id).png` (dibuat tools/art/cooking_art.py).
const ingredientCatalog = <Ingredient>[
  Ingredient('bawang', 'Bawang', Station.chop),
  Ingredient('tomat', 'Tomat', Station.chop),
  Ingredient('wortel', 'Wortel', Station.chop),
  Ingredient('cabai', 'Cabai', Station.chop),
  Ingredient('sawi', 'Sawi', Station.chop),
  Ingredient('telur', 'Telur', Station.boil),
  Ingredient('kentang', 'Kentang', Station.boil),
  Ingredient('mi', 'Mi', Station.boil),
  Ingredient('jagung', 'Jagung', Station.boil),
  Ingredient('bayam', 'Bayam', Station.boil),
  Ingredient('tempe', 'Tempe', Station.fry),
  Ingredient('tahu', 'Tahu', Station.fry),
  Ingredient('ayam', 'Ayam', Station.fry),
  Ingredient('ikan', 'Ikan', Station.fry),
  Ingredient('pisang', 'Pisang', Station.fry),
  Ingredient('nasi', 'Nasi', Station.fry),
];

Ingredient ingredientById(String id) =>
    ingredientCatalog.firstWhere((i) => i.id == id, orElse: () => throw ArgumentError('Bahan tidak dikenal: $id'));

class Recipe {
  const Recipe(this.name, this.ingredientIds);

  final String name;

  /// Urutan penting: step memakai N bahan pertama, jadi tiap awalan 3 bahan
  /// sudah mencakup minimal 2 stasiun berbeda.
  final List<String> ingredientIds;
}

/// Tambah resep baru di sini; tidak perlu ubah kode lain. Minimal 5 bahan per resep.
const recipes = <Recipe>[
  Recipe('Nasi Goreng Spesial', ['nasi', 'bawang', 'telur', 'cabai', 'tomat']),
  Recipe('Sop Sayur', ['wortel', 'kentang', 'jagung', 'bayam', 'tomat']),
  Recipe('Gado-gado', ['kentang', 'tahu', 'wortel', 'telur', 'tempe']),
  Recipe('Mi Goreng Ayam', ['mi', 'ayam', 'bawang', 'sawi', 'tomat']),
  Recipe('Pecel Ikan', ['ikan', 'bayam', 'tomat', 'tempe', 'cabai']),
];

/// Pesanan satu step: resep terpilih dan N bahan yang harus dimasak.
class Order {
  const Order({required this.recipe, required this.ingredients});

  final Recipe recipe;
  final List<Ingredient> ingredients;

  bool needs(String id) => ingredients.any((i) => i.id == id);
}

class OrderFactory {
  const OrderFactory._();

  /// Pilih resep acak (bukan [avoid]), ambil [count] bahan, dan susun baki
  /// berisi bahan pesanan ditambah [decoys] pengecoh (bahan di luar resep), diacak.
  static (Order, List<String>) create(
    Random rng, {
    required int count,
    required int decoys,
    Recipe? avoid,
  }) {
    final pool = [for (final r in recipes) if (r != avoid) r];
    final recipe = pool[rng.nextInt(pool.length)];
    final chosen = [for (final id in recipe.ingredientIds.take(count)) ingredientById(id)];

    final outside = [
      for (final i in ingredientCatalog)
        if (!recipe.ingredientIds.contains(i.id)) i,
    ]..shuffle(rng);
    final tray = [
      for (final i in chosen) i.id,
      for (final i in outside.take(decoys)) i.id,
    ]..shuffle(rng);
    return (Order(recipe: recipe, ingredients: chosen), tray);
  }
}
