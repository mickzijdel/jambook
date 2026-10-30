# Musical keys, spelled one way: the spelling with the fewer accidentals (Eb over D#, F# over Gb).
module MusicKey
  MAJORS = %w[ C Db D Eb E F F# G Ab A Bb B ].freeze
  MINORS = %w[ Cm C#m Dm Ebm Em Fm F#m Gm G#m Am Bbm Bm ].freeze
  KEYS = (MAJORS + MINORS).freeze

  NATURALS = { "C" => 0, "D" => 2, "E" => 4, "F" => 5, "G" => 7, "A" => 9, "B" => 11 }.freeze
  # A chord symbol (G, F#m7b5, A7sus4, C/G); words like Chorus, Bridge or Amazing don't match.
  CHORD = %r{\A[A-G][#b]?(?:m|maj|min|dim|aug|sus|add|M)?\d*(?:(?:add|sus|maj|b|#)\d+)*(?:/[A-G][#b]?)?\z}

  class << self
    def normalize(name)
      if (parsed = parse(name.to_s.strip))
        spell(*parsed)
      end
    end

    def transpose(name, delta)
      pitch, minor = parse(name.to_s.strip) || raise(ArgumentError, "unknown key: #{name.inspect}")
      spell(pitch + delta, minor)
    end

    def guess(sheet, format)
      if (chord = first_chord(sheet.to_s, format))
        normalize(chord[/\A[A-G][#b]?(m(?!aj))?/])
      end
    end

    private
      def parse(name)
        if (match = name.match(/\A([A-G])([#b]?)(m?)\z/))
          natural, accidental, minor = match.captures
          [ NATURALS.fetch(natural) + { "#" => 1, "b" => -1 }.fetch(accidental, 0), minor == "m" ]
        end
      end

      def spell(pitch, minor)
        (minor ? MINORS : MAJORS)[pitch % 12]
      end

      def first_chord(sheet, format)
        if format == "chordpro"
          sheet.scan(/\[([^\]\n]+)\]/).flatten.find { CHORD.match?(it) }
        else
          chord_line = sheet.lines.map(&:split).find { |tokens| tokens.any? && tokens.all?(CHORD) }
          chord_line&.first
        end
      end
  end
end
