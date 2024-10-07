package tokenization

import "core:strings"

prefix_matches :: proc(s: string, prefix: string) -> bool {
    return strings.has_prefix(s, prefix)
}

read_until :: proc(s: string, characters: string) -> string {
    character_index := strings.index_any(s, characters)
    if character_index == -1 {
        return s
    }

    v := s[:character_index]

    return v
}