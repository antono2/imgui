// Converts text offsets between platform encodings for selection and composition.
#pragma once

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <string>

namespace vimgui {

inline bool is_high_surrogate(char16_t unit) { return unit >= 0xd800 && unit <= 0xdbff; }
inline bool is_low_surrogate(char16_t unit) { return unit >= 0xdc00 && unit <= 0xdfff; }

inline uint32_t next_utf16_codepoint(const std::u16string& text, size_t& index)
{
    const char16_t first = text[index++];
    if (is_high_surrogate(first) && index < text.size() && is_low_surrogate(text[index]))
        return 0x10000u + ((uint32_t(first) - 0xd800u) << 10) +
               (uint32_t(text[index++]) - 0xdc00u);
    if (is_high_surrogate(first) || is_low_surrogate(first))
        return 0xfffdu;
    return first;
}

inline void append_utf8(std::string& result, uint32_t codepoint)
{
    if (codepoint <= 0x7f)
        result.push_back(char(codepoint));
    else if (codepoint <= 0x7ff)
    {
        result.push_back(char(0xc0 | (codepoint >> 6)));
        result.push_back(char(0x80 | (codepoint & 0x3f)));
    }
    else if (codepoint <= 0xffff)
    {
        result.push_back(char(0xe0 | (codepoint >> 12)));
        result.push_back(char(0x80 | ((codepoint >> 6) & 0x3f)));
        result.push_back(char(0x80 | (codepoint & 0x3f)));
    }
    else
    {
        result.push_back(char(0xf0 | (codepoint >> 18)));
        result.push_back(char(0x80 | ((codepoint >> 12) & 0x3f)));
        result.push_back(char(0x80 | ((codepoint >> 6) & 0x3f)));
        result.push_back(char(0x80 | (codepoint & 0x3f)));
    }
}

inline std::string utf16_to_utf8(const std::u16string& text)
{
    std::string result;
    result.reserve(text.size());
    for (size_t index = 0; index < text.size();)
        append_utf8(result, next_utf16_codepoint(text, index));
    return result;
}

// Android selection indices count UTF-16 code units; ImGui callback indices
// count UTF-8 bytes. A cursor inside a surrogate pair snaps to its start.
inline int utf16_index_to_utf8_offset(const std::u16string& text, int units)
{
    const size_t limit = std::min(text.size(), size_t(std::max(0, units)));
    int bytes = 0;
    for (size_t index = 0; index < limit;)
    {
        const uint32_t codepoint = next_utf16_codepoint(text, index);
        if (index > limit)
            break;
        bytes += codepoint <= 0x7f ? 1 : codepoint <= 0x7ff ? 2 : codepoint <= 0xffff ? 3 : 4;
    }
    return bytes;
}

inline int utf8_offset_to_utf16_index(const char* text, int byte_offset)
{
    int units = 0;
    for (int index = 0; index < byte_offset && text[index] != '\0';)
    {
        const unsigned char first = static_cast<unsigned char>(text[index]);
        int width = first < 0x80 ? 1 : first < 0xe0 ? 2 : first < 0xf0 ? 3 : 4;
        if (index + width > byte_offset)
            break;
        units += width == 4 ? 2 : 1;
        index += width;
    }
    return units;
}

inline std::u16string utf8_to_utf16(const char* text, int byte_count)
{
    std::u16string result;
    for (int index = 0; index < byte_count;)
    {
        const unsigned char first = static_cast<unsigned char>(text[index]);
        const int width = first < 0x80 ? 1 : first < 0xe0 ? 2 : first < 0xf0 ? 3 : 4;
        if (index + width > byte_count)
            break;
        uint32_t codepoint = first & (width == 1 ? 0x7f : width == 2 ? 0x1f : width == 3 ? 0x0f : 0x07);
        for (int continuation = 1; continuation < width; ++continuation)
            codepoint = (codepoint << 6) | (static_cast<unsigned char>(text[index + continuation]) & 0x3f);
        if (codepoint <= 0xffff)
            result.push_back(char16_t(codepoint));
        else
        {
            codepoint -= 0x10000;
            result.push_back(char16_t(0xd800 + (codepoint >> 10)));
            result.push_back(char16_t(0xdc00 + (codepoint & 0x3ff)));
        }
        index += width;
    }
    return result;
}

} // namespace vimgui
