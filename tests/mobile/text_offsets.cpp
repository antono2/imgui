#include "../../native/mobile/vimgui_text_offsets.h"

// CI builds this target in Release mode; keep the test checks executable.
#undef NDEBUG
#include <cassert>

int main()
{
    const std::u16string text = u"aé🙂z";
    const std::string utf8 = vimgui::utf16_to_utf8(text);
    assert(utf8 == u8"aé🙂z");
    assert(vimgui::utf8_to_utf16(utf8.data(), int(utf8.size())) == text);

    assert(vimgui::utf16_index_to_utf8_offset(text, 0) == 0);
    assert(vimgui::utf16_index_to_utf8_offset(text, 1) == 1);
    assert(vimgui::utf16_index_to_utf8_offset(text, 2) == 3);
    assert(vimgui::utf16_index_to_utf8_offset(text, 3) == 3);
    assert(vimgui::utf16_index_to_utf8_offset(text, 4) == 7);
    assert(vimgui::utf16_index_to_utf8_offset(text, 5) == 8);
    assert(vimgui::utf16_index_to_utf8_offset(text, 999) == 8);
    assert(vimgui::utf16_index_to_utf8_offset(text, -1) == 0);

    assert(vimgui::utf8_offset_to_utf16_index(utf8.c_str(), 1) == 1);
    assert(vimgui::utf8_offset_to_utf16_index(utf8.c_str(), 2) == 1);
    assert(vimgui::utf8_offset_to_utf16_index(utf8.c_str(), 3) == 2);
    assert(vimgui::utf8_offset_to_utf16_index(utf8.c_str(), 6) == 2);
    assert(vimgui::utf8_offset_to_utf16_index(utf8.c_str(), 7) == 4);
    assert(vimgui::utf8_offset_to_utf16_index(utf8.c_str(), 8) == 5);

    const std::u16string broken(1, char16_t(0xd800));
    assert(vimgui::utf16_to_utf8(broken) == u8"�");
}
