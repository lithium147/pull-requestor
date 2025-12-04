#!/usr/bin/env bash

# Handle the different ways of running `sed` without generating a backup file based on OS
# - GNU sed (Linux) uses `-i`
# - BSD sed (macOS) uses `-i ''`
SED_OPTIONS=(-i)
case "$(uname)" in
  Darwin*) SED_OPTIONS=(-i '')
esac

f="$1"  # file

function replaceTestWithExpected() {
  sed -E "${SED_OPTIONS[@]}" '
/@Test\(expected/{
  :b
  /.*@Test\(expected.*\).*\{.*\}$/!{N;bb
  }
  '"$1"'
}' "$f"
}

function replaceAnnotatedMethod() {
  sed -E "${SED_OPTIONS[@]}" '
/@'"$1"'/{
  :b
  /.*@'"$1"'.*\{$/!{N;bb
  }
  '"$2"'
}' "$f"
}

function replaceRule() {
  sed -E "${SED_OPTIONS[@]}" '
/@Rule/{
  :b
  /.*@Rule.*;$/!{N;bb
  }
  '"$1"'
}' "$f"
}

function replaceSingleLine() {
  sed -E "${SED_OPTIONS[@]}" "$1" "$f"
}

replaceSingleLine 's/([[:space:]]*)import[[:space:]]*org.junit.Test[[:space:]]*;$/\1import org.junit.jupiter.api.Test;/'
# TODO better to resolve all qualified annotations in a previous phase
replaceSingleLine 's/([[:space:]]+)@org.junit.Test([[:space:]]|$|\()/\1@Test\2/'
replaceSingleLine 's/([[:space:]]*)import[[:space:]]*org.junit.After[[:space:]]*;$/\1import org.junit.jupiter.api.AfterEach;/'
replaceSingleLine 's/([[:space:]]+)@After([[:space:]]|$|\()/\1@AfterEach\2/'
replaceSingleLine 's/([[:space:]]*)import[[:space:]]*org.junit.AfterClass[[:space:]]*;$/\1import org.junit.jupiter.api.AfterAll;/'
replaceSingleLine 's/([[:space:]]+)@AfterClass([[:space:]]|$|\()/\1@AfterAll\2/'
replaceSingleLine 's/([[:space:]]*)import[[:space:]]*org.junit.Before[[:space:]]*;$/\1import org.junit.jupiter.api.BeforeEach;/'
replaceSingleLine 's/([[:space:]]+)@Before([[:space:]]|$|\()/\1@BeforeEach\2/'
replaceSingleLine 's/([[:space:]]*)import[[:space:]]*org.junit.BeforeClass[[:space:]]*;$/\1import org.junit.jupiter.api.BeforeAll;/'
replaceSingleLine 's/([[:space:]]+)@BeforeClass([[:space:]]|$|\()/\1@BeforeAll\2/'

# XXX @ExtendWith might not be required for spring tests since they could be included indirectly
# for example, @SpringBootTest includes SpringExtension
#@RunWith(SpringRunner.class) >>> @ExtendWith(SpringExtension.class)
replaceSingleLine 's/^[[:space:]]*@RunWith[[:space:]]*\([[:space:]]*SpringRunner.class[[:space:]]*\)[[:space:]]*$/@ExtendWith(SpringExtension.class)/'
#@RunWith(SpringJUnit4ClassRunner.class) >>> @ExtendWith(SpringExtension.class)
replaceSingleLine 's/^[[:space:]]*@RunWith[[:space:]]*\([[:space:]]*SpringJUnit4ClassRunner.class[[:space:]]*\)[[:space:]]*$/@ExtendWith(SpringExtension.class)/'

#@RunWith(MockitoJUnitRunner.class) >>> @ExtendWith(MockitoExtension.class)
replaceSingleLine 's/^([[:space:]]*)@RunWith[[:space:]]*\([[:space:]]*MockitoJUnitRunner.class[[:space:]]*\)[[:space:]]*$/\1@ExtendWith(MockitoExtension.class)\
\1@MockitoSettings(strictness = Strictness.WARN)  \/\/ required for backward compatibility with MockitoJUnitRunner, probably can be removed/'

#@RunWith(@RunWith(MockitoJUnitRunner.StrictStubs.class)) >>> @ExtendWith(MockitoExtension.class)
replaceSingleLine 's/^[[:space:]]*@RunWith[[:space:]]*\([[:space:]]*MockitoJUnitRunner.StrictStubs.class[[:space:]]*\)[[:space:]]*$/@ExtendWith(SpringExtension.class)/'

# TODO indent the wrapped code to a deeper level
replaceTestWithExpected 's/([[:space:]]*)@Test\(expected[[:space:]]*=[[:space:]]*([^)]*)\)(.*\{)\n([[:space:]]*)([^}]*|[^}]*\{[^}]*\}[^}]*)\n([[:space:]]*})/\1@Test\3\
\4assertThatExceptionOfType(\2).isThrownBy(() -> {\
\4\5\
\4});\
\6/'

# default visibility for test methods
annotatedMethods=('BeforeAll' 'BeforeEach' 'AfterAll' 'AfterEach' 'Test')
for annotation in ${annotatedMethods[@]}; do
  replaceAnnotatedMethod $annotation 's/([[:space:]]*)@'"$annotation"'(.*)(public |protected |private )(.*\{)/\1@'"$annotation"'\2\4/'
done
# Test methods should not begin with 'test' or 'test_'
# \l - lowercase next letter in match (doesn't work on mac apparently)
# XXX not really related to junit5, but its a convenient place for it, for now
replaceAnnotatedMethod 'Test' 's/([[:space:]]*)@Test(.*)(void )test[_]*(.*\{)/\1@Test\2\3\l\4/'

# special case for runFeaturesWithAuthenticationAndGenerateReport()
# make it default visibility so child classes can have default visibility
replaceSingleLine 's/([[:space:]]*)(public |protected |private )(.*runFeaturesWithAuthenticationAndGenerateReport\(\))/\1\3/'

# test classes can have default visibility
# standard test class names: Test|Tests|TestCase|IT|ITCase
replaceSingleLine 's/^public class (.*(Test[s]?|Runner|IT)([[:space:]]|$|<|\{))/class \1/'

#import static org.assertj.core.api.Assertions.assertThatExceptionOfType;

#    @Test(expected = IllegalArgumentException.class)
#    public void getGcsUrl_IllegalArgumentException() {
#        GcpUrlUtil.getGcsUrl("xx", "projectId");
#    }
#>>>>
#    @Test
#    public void getGcsUrl_IllegalArgumentException() {
#        assertThatExceptionOfType(IllegalArgumentException.class)
#                .isThrownBy(() -> {
#                    GcpUrlUtil.getGcsUrl("xx", "projectId")
#                });
#    }

replaceRule 's/([[:space:]]*)@Rule.*TemporaryFolder[[:space:]]+([^= ]*)[[:space:]]*=([[:space:]]*)new TemporaryFolder\(\)[[:space:]]*;/\1@TempDir\
\1File \2Root;\
\1TemporaryFolder \2;\
\
\1@BeforeEach\
\1void \2Init() throws IOException {\
\1\1\2 = new TemporaryFolder(\2Root);\
\1\1\2.create();\
\1}\
/'

#    @Rule
#    public TemporaryFolder tmpFolder = new TemporaryFolder();
#>>>>
#    @TempDir
#    public File tmpFolderRoot;
#    public TemporaryFolder tmpFolder;
#    @BeforeEach
#    public void tmpFolderInit() throws IOException {
#        tmpFolder = new TemporaryFolder(tmpFolderRoot);
#        tmpFolder.create();
#    }

# PowerMock??? - doesn't seem to support junit5, perhaps exclude these classes
# https://alm-github.systems.uk.hsbc/raven-cr/raven-hmic-service/blob/master/src/test/java/com/hsbc/gbm/grt/hmic/manager/raven/crbt/batch/dailycalib/calibrationservic/CalibrationServiceControllerTest.java
#@RunWith(PowerMockRunner.class)
#@PowerMockRunnerDelegate(SpringJUnit4ClassRunner.class)
#@PowerMockIgnore({"javax.management.*","org.apache.http.conn.ssl.*","javax.net.ssl.*"})
#@ActiveProfiles("test")
#@PrepareForTest({FileUtils.class,CalibrationServiceController.class})


