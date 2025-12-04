# PullRequestor
Automated creation of pull requests for code improvements

## Public github rate limiting

There is an issue where calls github.com get rate limited.  This mostly affects dependabot but also affects some other tools where it checks for latest versions from github.com

Here is the error message:

    01:52:44  /home/dependabot/.bundle/gems/octokit-4.20.0/lib/octokit/response/raise_error.rb:14:in `on_complete':
        GET https://api.github.com/repos/micrometer-metrics/micrometer/contents/: 403 - API rate limit exceeded for 34.240.97.46.
        (But here's the good news: Authenticated requests get a higher rate limit. Check out the documentation for more details.)
        // See: https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting (Octokit::TooManyRequests)

## Future ideas

The following are some ideas for further code improvements:


### No double brace maps, eg:

    public static final Map<String, Object> TEST_MAP = new HashMap<>(){{
         put(SOME_MAP_KEY_1, SOME_MAP_VALUE_1);
         put(SOME_MAP_KEY_2, SOME_MAP_VALUE_2);
     }};

### Template projects
push changes from template projects
could have a template.yml file in the project to configure which template to use

### Long line wrapping:

wrap long lines where a suitable place can be found.
assertThat() is good candidate


### Extract actual as a variable, eg:

    assertThat(new TextFormatter(text).withPaddingRightUpTo(0).build()).isEqualTo(text);

    var actual = new TextFormatter(text).withPaddingRightUpTo(0).build();
    assertThat(actual).isEqualTo(text);

### Missing diamond operator

new ArrayList() -> new ArrayList<>()

### Version bumping
    could have tool that bumps a specific version in a specific project
    so the release jobs could trigger this job after creating new releases

    bump(project, artefact, version)

### Remove brackets from this:

        var exception = (catchThrowableOfType(() -> pureSerialDriverResolver.attemptPrinterDriverResolution(pureSerialPrinterDeviceObserver), UnknownPureSerialDeviceException.class));

### Modifier order:
    private final static String traceId = "traceId";

### update-env script

base64 -d scripts/update-env.bat.base64 > /z/update-env.bat
base64 /z/update-env.bat > scripts/update-env.bat.base64 

