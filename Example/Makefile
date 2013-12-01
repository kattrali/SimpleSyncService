BUILD_TOOL=xcodebuild
DEFAULT_BUILD_ARGS=-workspace SampleProject.xcworkspace -scheme SampleProject

default: clean spec

clean:
	$(BUILD_TOOL) $(DEFAULT_BUILD_ARGS) clean

spec:
	$(BUILD_TOOL) $(DEFAULT_BUILD_ARGS) test

install:
	gem update cocoapods
	pod install

ci: clean spec
