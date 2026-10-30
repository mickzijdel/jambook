require "test_helper"

# Every vendored JavaScript package is named in NOTICE.md at its pinned version, so a re-pin can't
# leave the notice describing an old one (ChordSheetJS is GPL-2.0-only, unlike Jambook's MIT code).
class VendorNoticeTest < ActiveSupport::TestCase
  test "NOTICE.md names every vendored JavaScript package at its pinned version" do
    notice = Rails.root.join("NOTICE.md").read
    Rails.root.glob("vendor/javascript/*.js").each do |file|
      package = file.open(&:gets)[%r{\A// (\S+@\S+) downloaded from}, 1]

      assert package, "#{file.basename} has no importmap download header"
      assert_includes notice, package
    end
  end
end
