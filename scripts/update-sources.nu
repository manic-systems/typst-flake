#!/usr/bin/env nu

const source_file = "sources.json"
const typst_repo = "https://github.com/typst/typst.git"

def prefetch [url: string] {
  let result = (nix flake prefetch $url --json | complete)

  if $result.exit_code != 0 {
    error make {
      msg: $"failed to prefetch ($url)"
      label: {
        text: $result.stderr
        span: (metadata $url).span
      }
    }
  }

  let prefetched = ($result.stdout | from json)

  $prefetched.locked
  | reject --optional revCount
  | upsert narHash $prefetched.hash
}

def sort-versions [versions: record] {
  $versions
  | transpose version source
  | sort-by --reverse source.lastModified
  | reduce --fold {} {|entry, acc| $acc | upsert $entry.version $entry.source }
}

def main [] {
  mut sources = (open $source_file)

  $sources = (
    $sources
    | upsert main (prefetch "github:typst/typst/main")
  )

  mut versions = $sources.versions
  let tags = (http get "https://api.github.com/repos/typst/typst/tags?per_page=100")

  for tag in $tags {
    let tag_name = $tag.name

    if not ($tag_name | str starts-with "v") {
      continue
    }

    let version = ($tag_name | str replace --regex "^v" "")

    if ($versions | get --optional $version) == null {
      let source = (prefetch $"git+($typst_repo)?ref=refs/tags/($tag_name)")
      $versions = ($versions | upsert $version $source)
    }
  }

  let sorted_versions = (sort-versions $versions)
  let latest = (
    $sorted_versions
    | transpose version source
    | first
    | get version
  )

  let rendered = (
    $sources
    | upsert latest $latest
    | upsert versions $sorted_versions
    | to json --indent 2
  )

  $"($rendered)\n" | save --force $source_file
}
