BUILD_TOOL=xcodebuild
DEFAULT_BUILD_ARGS=-workspace SampleProject.xcworkspace -scheme SampleProject

default: clean spec

clean:
	$(BUILD_TOOL) $(DEFAULT_BUILD_ARGS) clean | xcpretty -c

spec:
	$(BUILD_TOOL) $(DEFAULT_BUILD_ARGS) test | xcpretty -c; exit ${PIPESTATUS[0]}

install:
	gem install xcpretty --no-ri --no-rdoc

ci: clean spec
