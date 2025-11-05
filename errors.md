# Project Error Log

This document lists all identified bugs, potential issues, and suggested improvements in the codebase.

## Bugs & Errors

### Backend & Logic Issues

1.  **Incomplete Read/Write Limit Enforcement:** The logic to track daily Firestore reads and writes is not fully implemented across all functions in `user_provider.dart`. This could lead to exceeding the daily limits of 5 reads and 3 writes per user, causing features to fail.
2.  **AdMob Integration Issues:**
    *   The app uses test ad unit IDs, which need to be replaced with production IDs.
    *   Interstitial ads, as mentioned in the plan, are not implemented.
    *   Comprehensive handling for ad-related edge cases (e.g., network failures, no ad fill) is missing.
3.  **Daily Reward Claim Logic Error:** The `claimDailyReward` function in `user_provider.dart` incorrectly prevents users from claiming their daily reward. The logic checks if `lastActiveDate` is today, which can be true even if the reward hasn't been claimed, effectively locking users out.

### UI & Feature Functionality Bugs

1.  **Missing Sign-Up Flow:** The "Create Account" button on the `AuthScreen` does not navigate to a sign-up screen, making it impossible for new users to register.
2.  **Game Screen Errors:**
    *   **Asynchronous Race Conditions:** All game screens (`Watch Ads`, `Spin & Win`, `Tic-Tac-Toe`) have a potential race condition where the UI may not update correctly after a user action (e.g., watching an ad) because the asynchronous calls to update user data are not consistently awaited.
    *   **Use of Mock Data:** The `Tic-Tac-Toe` screen uses hardcoded mock data for game statistics instead of fetching real data from the `UserProvider`. The `Watch Ads` and `Spin & Win` screens use mock data for their activity/history lists.
3.  **Withdrawal Screen UI Missing Input Fields:** The withdrawal screen is missing the necessary text fields for users to enter their UPI ID or bank account details. The app currently uses hardcoded placeholder data when submitting a withdrawal request, making the feature non-functional for real users.
4.  **Transaction History Not Working:** The transaction history screen is not functional. It displays a hardcoded list of placeholder transactions instead of fetching the user's actual transaction history from Firestore.

## Suggested Improvements

### `AuthScreen`

1.  **Implement Sign-Up Flow:** Create a dedicated sign-up screen that allows new users to register with their email and password.
2.  **Add Referral Code on Sign-Up:** Include a field for users to enter a referral code during the sign-up process, as specified in the `plan.md`.
3.  **Add "Forgot Password" Functionality:** Implement a "Forgot Password" feature to allow users to reset their passwords.
4.  **Improve Error Handling:** Provide more specific and user-friendly error messages for authentication failures (e.g., "User not found," "Incorrect password").

### Game Screens (`Watch Ads`, `Spin & Win`, `Tic-Tac-Toe`)

1.  **Fetch Real Data:** Replace all mock data with real data fetched from the `UserProvider` and `ConfigProvider`.
2.  **Implement Incomplete Features:** Implement the "Get Hint" and game rules buttons on the `Tic-Tac-Toe` screen.

### `HomeScreen`

1.  **Improve UI/UX:** The home screen is very basic. It could be enhanced by:
    *   Displaying more user information, such as daily earnings or a progress bar towards the next withdrawal.
    *   Disabling or hiding the "Claim Daily Reward" button after it has been used for the day.
    *   Making the overall layout more engaging and visually appealing.

### `InviteScreen`

1.  **Display User ID Instead of Name:** The list of referred users shows the raw `refereeId` instead of a user-friendly display name.
2.  **Hardcoded Referral Message:** The message shared with friends is hardcoded in the app, making it difficult to update or A/B test.
3.  **Add "Copy to Clipboard" Button:** There is no button to easily copy the referral code to the clipboard.

### `ProfileScreen`

1.  **Incomplete "Payment Methods" Feature:** The "Payment Methods" button is not implemented and does not navigate to a screen where users can manage their withdrawal details.
2.  **Improve Profile Picture Handling:** The profile picture is loaded directly from a URL, which can be inefficient. Using a cached network image solution would improve performance and user experience.
3.  **Enhance User Stats:** The screen could be improved by displaying more user statistics, such as total coins earned or the number of successful referrals.

### `EditProfileScreen`

1.  **Non-functional Save Button:** The "Save Changes" button does not actually update the user's display name in Firestore. It only simulates a network request.
2.  **Allow Profile Picture Changes:** The screen should include an option for users to change their profile picture.

### `SettingsScreen`

1.  **Non-persistent Settings:** The user's settings are not saved to the device, so they will be reset every time the app is closed.
2.  **Dark Mode Not Implemented:** The "Dark Mode" switch is present, but the app does not have a dark theme.
3.  **Add More Settings Options:** The screen could be improved by adding more settings, such as sound effects or language selection.

### `HelpSupportScreen`

1.  **Non-functional Contact Button:** The "Contact Support" button is disabled and does not provide a way for users to get in touch with support.
2.  **Hardcoded FAQ Data:** The FAQ content is hardcoded in the app, making it difficult to update without releasing a new version.
3.  **Expand FAQ Section:** The FAQ section is very basic and should be expanded with more questions and answers.

### `OnboardingScreen`

1.  **Don't Show Onboarding to Existing Users:** The app does not check if the user has already completed the onboarding process, so it will be shown every time the app is launched by a new user.
2.  **Use Engaging Visuals:** The onboarding screen uses placeholder images. Custom illustrations or app screenshots would be more effective.
3.  **Hardcoded Onboarding Data:** The text and images for the onboarding flow are hardcoded, making them difficult to update.

### `SplashScreen`

1.  **Improve Visuals:** The splash screen is very basic. It should be enhanced with the app's logo and a more appealing loading animation.
2.  **Refine Navigation Logic:** The initial navigation logic is simple. For a more robust app, a dedicated navigation service could be used to handle the initial routing based on the user's authentication state and onboarding completion status.
