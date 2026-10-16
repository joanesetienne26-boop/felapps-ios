# felapps-ios

iOS app template used by Felapps. The `ios-publish` Codemagic workflow is
triggered by the Felapps backend: `configure.sh` generates the Xcode project
from environment variables (app name, bundle ID, website URL, icon, version),
then the app is built, signed with the App Store Connect API key, and uploaded
to TestFlight.
