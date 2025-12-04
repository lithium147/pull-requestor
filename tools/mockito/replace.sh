#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

f="$1"  # file

function replace() {
  sed -E "${SED_OPTIONS[@]}" '
/@Mock$/{
  :b
  /.*@Mock.*;.*$/!{N;bb
  }
  '"$1"'
}' "$f"
}

function replaceWithParams() {
  sed -E "${SED_OPTIONS[@]}" '
/@Mock\([^)]*\)$/{
  :b
  /.*@Mock.*;.*$/!{N;bb
  }
  '"$1"'
}' "$f"
}

# @Mock
# private ReceiptServiceMeterRegistry mockedStats;
# >>>>>>
# private final ReceiptServiceMeterRegistry mockedStats = mock(ReceiptServiceMeterRegistry.class);

# exclude modifiers: private/protected/final/static
replace 's/([[:space:]]*)@Mock[[:space:]]*(private|protected|static|final|[[:space:]]*)*[[:space:]]*([a-zA-Z0-9_]*)[[:space:]]*([a-zA-Z0-9_]*)[[:space:]]*;[[:space:]]*$/\1private final \3 \4 = mock(\3.class);/'

#    @Mock(answer = Answers.RETURNS_DEEP_STUBS)
#    private ChunkContext chunkContext;
#>>>>>
#    private final ChunkContext chunkContext = mock(ChunkContext.class, RETURNS_DEEP_STUBS);
#import static org.mockito.Mockito.RETURNS_DEEP_STUBS;
replaceWithParams 's/([[:space:]]*)@Mock\(answer[[:space:]]*=[[:space:]]*(Answers.)?RETURNS_DEEP_STUBS[[:space:]]*\)[[:space:]]*(private|protected|static|final|[[:space:]]*)*[[:space:]]*([a-zA-Z0-9_]*)[[:space:]]*([a-zA-Z0-9_]*)[[:space:]]*;[[:space:]]*$/\1private final \4 \5 = mock(\4.class, RETURNS_DEEP_STUBS);/'


# XXX only run these manually as they will likely break things
#sed -E "${SED_OPTIONS[@]}" '/@InjectMocks/d' "$f"
#sed -E "${SED_OPTIONS[@]}" '/@ExtendWith.*MockitoExtension/d' "$f"

# remove these:
# @InjectMocks
# @ExtendWith(MockitoExtension.class)
# @ExtendWith({MockitoExtension.class})

