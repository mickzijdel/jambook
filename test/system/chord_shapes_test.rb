require "application_system_test_case"

# findShapes and diagramSvg are plain JavaScript; they run in the browser with the real chord data.
class ChordShapesTest < ApplicationSystemTestCase
  SHAPES = JSON.parse(Rails.root.join("app/assets/data/guitar_chords.json").read)

  setup { visit new_guest_access_path }

  test "chord names find their shapes, whatever the spelling" do
    cases = {
      "C" => %w[C major], "Am" => %w[A minor], "A#m" => %w[Bb minor], "Dbmaj7" => %w[C# maj7], "CM7" => %w[C maj7],
      "F#m7b5" => %w[F# m7b5], "Gø" => %w[G m7b5], "Asus" => %w[A sus4], "Esus2" => %w[E sus2], "D7sus4" => %w[D 7sus4],
      "Cadd9" => %w[C add9], "Bdim" => %w[B dim], "Eaug" => %w[E aug], "G6" => %w[G 6], "Fm6" => %w[F m6],
      "C/E" => %w[C /E], "D/F#" => %w[D /F#], "D/Gb" => %w[D /F#], "Am/G" => %w[A m/G], "G/B" => %w[G /B],
      # Spellings seen in the library.
      "Esus7" => %w[E 7sus4], "Am(ma7)" => %w[A mmaj7], "F(9)" => %w[F add9], "G(2)" => %w[G add9], "D(4)" => %w[D sus4],
      "EbDim" => %w[Eb dim], "C*" => %w[C major], "Cadd9*" => %w[C add9], "Gma7" => %w[G maj7],
      "Cma9" => %w[C maj9], "Ama9" => %w[A maj9], "Ammaj9" => %w[A mmaj9], "Gm2" => %w[G madd9], "A\\C#" => %w[A /C#],
      "F#m7(b5)" => %w[F# m7b5], "G7(b9)" => %w[G 7b9], "B7(#5)" => %w[B aug7]
    }

    found = lookup(cases.keys).transform_values { |result| result && result["positions"] }

    assert_equal cases.transform_values { |key, suffix| SHAPES.dig(key, suffix) }, found
  end

  test "an unusual chord says what it shows instead" do
    notes = lookup([ "C", "Am7/G", "Bm7\\A", "Bb/D", "Cmaj7#11", "Ebm(maj9)" ]).transform_values { |result| result["note"] }

    assert_equal({ "C" => nil, "Am7/G" => "Play G in the bass.", "Bm7\\A" => "Play A in the bass.", "Bb/D" => "Play D in the bass.",
      "Cmaj7#11" => "Shown as C, the nearest chord in the chord book.", "Ebm(maj9)" => "Shown as Ebm, the nearest chord in the chord book." }, notes)
  end

  # Words the Ultimate Guitar parser took for chords, seen in the library.
  test "something that isn't a chord has no shapes" do
    words = [ "N.C.", "H7", "", "Ah-Ah,", "From", "Californication", "Chords:", "E-A-D-G-B-e", "Em-G7-C-B7" ]

    assert_equal words.index_with(nil), lookup(words)
  end

  test "a power chord gets its two shapes, root on the low E string first when that is lower" do
    frets = lookup([ "A5", "E5", "F#5", "G5/D" ]).transform_values { |result| result["positions"].map { |shape| shape.values_at("frets", "baseFret") } }

    assert_equal({ "A5" => [ [ [ -1, 0, 2, 2, -1, -1 ], 1 ], [ [ 1, 3, 3, -1, -1, -1 ], 5 ] ],
      "E5" => [ [ [ 0, 2, 2, -1, -1, -1 ], 1 ], [ [ -1, 1, 3, 3, -1, -1 ], 7 ] ],
      "F#5" => [ [ [ 1, 3, 3, -1, -1, -1 ], 2 ], [ [ -1, 1, 3, 3, -1, -1 ], 9 ] ],
      "G5/D" => [ [ [ 1, 3, 3, -1, -1, -1 ], 3 ], [ [ -1, 1, 3, 3, -1, -1 ], 10 ] ] }, frets)
  end

  test "a diagram marks muted and open strings, fingers, and says the shape in words" do
    drawn = diagram("C", SHAPES.dig("C", "major", 0))

    assert_equal({ "dots" => 3, "muted" => 1, "open" => 2, "barres" => 0, "base" => nil,
      "label" => "C: low E muted, A fret 3, D fret 2, G open, B fret 1, high E open" }, drawn)
  end

  test "a barre shape up the neck shows the barre and the fret it starts on" do
    drawn = diagram("C", SHAPES.dig("C", "major", 1))

    assert_equal [ 1, "3fr", "C: low E fret 3, A fret 3, D fret 5, G fret 5, B fret 5, high E fret 3" ], drawn.values_at("barres", "base", "label")
  end

  private
    def lookup(symbols)
      evaluate_async_script(<<~JS, symbols, ActionController::Base.helpers.asset_path("guitar_chords.json"))
        const [symbols, url, done] = arguments
        Promise.all([ import("helpers/chord_shapes"), fetch(url).then((response) => response.json()) ])
          .then(([ { findShapes }, chords ]) => done(Object.fromEntries(symbols.map((symbol) => [ symbol, findShapes(symbol, chords) ]))))
          .catch((error) => done(String(error)))
      JS
    end

    def diagram(name, shape)
      evaluate_async_script(<<~JS, name, shape)
        const [name, shape, done] = arguments
        import("helpers/chord_shapes").then(({ diagramSvg }) => {
          const svg = new DOMParser().parseFromString(diagramSvg(name, shape), "image/svg+xml").documentElement
          const count = (selector) => svg.querySelectorAll(selector).length
          done({ dots: count(".cd-dot"), muted: count(".cd-muted"), open: count(".cd-open"), barres: count(".cd-barre"),
            base: svg.querySelector(".cd-base")?.textContent ?? null, label: svg.getAttribute("aria-label") })
        }).catch((error) => done(String(error)))
      JS
    end
end
