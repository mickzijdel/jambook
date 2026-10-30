require "application_system_test_case"

# wrapTab is plain JavaScript; it runs in the browser because the app's JavaScript lives in the import map.
class TabWrapTest < ApplicationSystemTestCase
  setup { visit new_guest_access_path }

  test "a staff that fits is left alone" do
    staff = [ "e|--0--|--1--|", "B|--1--|--1--|" ]

    assert_equal staff, wrap(staff, 40)
  end

  test "a long staff breaks at bar lines and repeats the string names" do
    assert_equal [ "e|--0--|--1--|", "B|--1--|--1--|", "", "e|--3--|", "B|--0--|" ],
      wrap([ "e|--0--|--1--|--3--|", "B|--1--|--1--|--0--|" ], 14)
  end

  test "a repeat mark stays with the last part" do
    assert_equal [ "e|--0--|--1--|", "B|--1--|--1--|", "", "e|--3--|", "B|--0--| x2" ],
      wrap([ "e|--0--|--1--|--3--|", "B|--1--|--1--|--0--| x2" ], 14)
  end

  test "chord names above a staff move with their bars" do
    assert_equal [ "  Am    C", "e|--0--|--1--|", "B|--1--|--1--|", "", "  G", "e|--3--|", "B|--0--|" ],
      wrap([ "  Am    C     G", "e|--0--|--1--|--3--|", "B|--1--|--1--|--0--|" ], 14)
  end

  test "each staff in a tab breaks on its own" do
    assert_equal [ "e|--0--|--1--|", "B|--1--|--1--|", "", "e|--3--|", "B|--0--|", "", "e|--5--|", "B|--5--|" ],
      wrap([ "e|--0--|--1--|--3--|", "B|--1--|--1--|--0--|", "", "e|--5--|", "B|--5--|" ], 14)
  end

  test "a tab whose bars don't line up is left for the screen to shrink" do
    staff = [ "e|--0--|--1--|--3--|", "B |--1--|--1--|--0--|" ]

    assert_equal staff, wrap(staff, 14)
  end

  test "without inner bar lines it breaks where every string rests, never inside a fret number" do
    staff = [ "e|-----12-----14-----|", "B|---------0---------|" ]
    out = wrap(staff, 12)

    assert_wrapped staff, out, columns: 12
  end

  # The next three are shapes from real Ultimate Guitar tabs.
  test "a double bar at the start isn't a part of its own" do
    assert_equal [ "e||--12----|", "B||--------|", "", "e|------|", "B|------|" ],
      wrap([ "e||--12----|------|", "B||--------|------|" ], 14)
  end

  test "a long silent stretch after the last note still breaks" do
    assert_equal [ "A|--0-2-4--------", "E|---------------", "", "A|--------------|", "E|--------------|" ],
      wrap([ "A|--0-2-4----------------------|", "E|-----------------------------|" ], 18)
  end

  test "a staff of rests only still breaks" do
    assert_equal [ "D|----------|", "A|----------|", "", "D|----------|", "A|----------|" ],
      wrap([ "D|----------|----------|", "A|----------|----------|" ], 14)
  end

  test "the parts come out even, not a full row and a scrap" do
    assert_equal [ "e|--0----1----2---", "B|--1----1----3---", "", "e|-3----5----7--|", "B|-3----5----8--|" ],
      wrap([ "e|--0----1----2----3----5----7--|", "B|--1----1----3----3----5----8--|" ], 24)
  end

  test "evening out never trades a bar line for a break inside a bar" do
    assert_equal [ "e||--12----|", "B||--------|", "", "e|------|", "B|------|" ],
      wrap([ "e||--12----|------|", "B||--------|------|" ], 14)
  end

  test "300 generated tabs keep every note, fit the width and never split a fret number" do
    random = Random.new(42)
    cases = Array.new(300) { [ random_tab(random), [ 16, 24, 37, 45, 60 ].sample(random: random) ] }
    results = evaluate_async_script(<<~JS, cases)
      const [cases, done] = arguments
      import("helpers/tab_wrap").then(({ wrapTab }) => done(cases.map(([lines, columns]) => wrapTab(lines, columns)))).catch((error) => done(String(error)))
    JS

    cases.zip(results).each { |(staff, columns), out| assert_wrapped staff, out, columns: columns }
  end

  private
    def wrap(lines, columns)
      evaluate_async_script(<<~JS, lines, columns)
        const [lines, columns, done] = arguments
        import("helpers/tab_wrap").then(({ wrapTab }) => done(wrapTab(lines, columns))).catch((error) => done(String(error)))
      JS
    end

    # Joining the parts back up, string names dropped, gives the staff as written.
    def assert_wrapped(staff, out, columns:)
      parts = out.slice_when { |_line, following| following.empty? }.map { |part| part.reject(&:empty?) }
      context = "#{staff.join("\n")}\n→\n#{out.join("\n")}"

      parts.each { |part| assert_equal staff.size, part.size, context }
      staff.each_with_index do |line, i|
        pieces = parts.map { |part| part[i] }

        assert_equal line, pieces.first + pieces.drop(1).map { |piece| piece[2..] }.join, context
        pieces.each_cons(2) { |before, after| assert_not before.match?(/\d\z/) && after[2]&.match?(/\d/), "split fret number\n#{context}" }
      end
      widest_bar = staff.map { |line| line.scan(/[^|]*\|/).map(&:size).max || 0 }.max
      assert out.all? { |line| line.size <= columns }, "too wide for #{columns}\n#{context}" if widest_bar + 2 <= columns
    end

    # Four or six strings, one to eight bars, frets 0-24, hammer-ons and slides, sometimes a repeat mark.
    def random_tab(random)
      names = random.rand < 0.3 ? %w[G D A E] : %w[e B G D A E]
      lines = names.map { |name| +"#{name}|" }
      random.rand(1..8).times do
        until lines.first.size - lines.first.rindex("|") > random.rand(6..22)
          if random.rand < 0.3
            note = [ (0..24).to_a.sample(random: random).to_s, "5h7", "7/9", "12p10" ].sample(random: random)
            string = random.rand(names.size)
            lines.each_with_index { |line, j| line << (j == string ? note : "-" * note.size) }
          else
            lines.each { |line| line << "-" }
          end
        end
        lines.each { |line| line << "|" }
      end
      lines.last << " x#{random.rand(2..4)}" if random.rand < 0.3
      lines
    end
end
