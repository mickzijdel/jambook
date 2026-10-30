require "application_system_test_case"

# Auto-scroll belongs to one device: it never reaches the server or anyone else's phone.
class AutoscrollTest < ApplicationSystemTestCase
  setup do
    @song = Song.create!(title: "Long", artist: "Traditional", written_key: "G", sheet_format: "chordpro",
      sheet: Array.new(80) { |i| "[G]Line #{i} of a long song" }.join("\n"))
    Room.instance.play(@song)
    enter_guest_password

    assert_selector ".lyrics", text: "79 of a long song"
  end

  test "auto-scroll moves the page down until it is paused" do
    click_on "Scroll"

    assert_scrolls_past 10

    click_on "Pause"
    paused_at = scroll_y
    sleep 0.5

    assert_in_delta paused_at, scroll_y, 1
    assert_button "Scroll"
  end

  test "the speed goes up and down, and this device remembers it for the song" do
    assert_speed 4
    click_on "Scroll faster"
    click_on "Scroll faster"
    click_on "Scroll slower"

    assert_speed 5

    visit root_path

    assert_speed 5
  end

  test "auto-scroll stops at the end of the song" do
    execute_script("window.scrollTo(0, document.documentElement.scrollHeight - window.innerHeight - 30)")
    6.times { click_on "Scroll faster" }
    click_on "Scroll"

    assert_button "Scroll", wait: 4
  end

  test "a key change from the host keeps it scrolling" do
    click_on "Scroll"
    Room.instance.transpose(1)

    assert_selector "#room-key .key", text: "Ab"
    assert_button "Pause"
    assert_speed 4
    before = scroll_y

    assert_scrolls_past before + 5
  end

  test "a new song from the host stops auto-scroll at the top" do
    click_on "Scroll"

    assert_scrolls_past 10

    Room.instance.play(songs(:amazing_grace))

    assert_selector "h1", text: "Amazing Grace"
    assert_button "Scroll"
    sleep 0.5

    assert_equal 0, scroll_y
  end

  private
    def scroll_y
      evaluate_script("window.scrollY")
    end

    def assert_scrolls_past(y, within: 4)
      deadline = Time.current + within
      sleep 0.05 until scroll_y > y || Time.current > deadline

      assert_operator scroll_y, :>, y
    end

    def assert_speed(speed)
      assert_selector "[data-autoscroll-target=speed]", text: speed.to_s
    end
end
