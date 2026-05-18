import '../models/app_language.dart';

class Tr {
  Tr(this.language);

  final AppLanguage language;

  static const _en = {
    'welcome_title': 'Welcome to Kashta',
    'welcome_subtitle': 'Discover places, plan trips, and share adventures.',
    'email': 'Email',
    'password': 'Password',
    'full_name': 'Full name',
    'username': 'Username',
    'sign_in': 'Sign In',
    'sign_up': 'Sign Up',
    'continue_google': 'Continue with Google',
    'sign_in_phone': 'Sign in with phone number',
    'continue_guest': 'Continue as Guest',
    'email_password_required': 'Email and password are required',
    'full_name_required': 'Full name is required',
    'username_required': 'Username is required',
    'username_taken':
        'This username is already taken. Please choose another one.',
    'email_already_registered':
        'This email is already registered. Please sign in instead.',
    'could_not_create_user_profile':
        'Could not create user profile. Please try again.',
    'phone_number': 'Phone Number',
    'phone_hint': '+9665XXXXXXXX',
    'phone_failed': 'Phone sign-in failed',
    'sms_code': 'SMS Code',
    'sms_hint': 'Enter OTP',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'explore': 'Explore',
    'trips': 'Trips',
    'groups': 'Groups',
    'profile': 'Profile',
    'safety_checkin': 'Safety',
    'safety_checkin_title': 'Safety Check-in',
    'safety_checkin_profile_subtitle':
        'Prepare and share your trip safety details.',
    'safety_my_info': 'My Safety Info',
    'safety_name': 'Name',
    'safety_phone': 'Phone',
    'safety_vehicle_type': 'Vehicle Type',
    'safety_vehicle_color': 'Vehicle Color',
    'safety_plate_number': 'Plate Number',
    'safety_saved_info_note':
        'Saved safety information is used only to prepare your check-in message faster.',
    'safety_save_info': 'Save Safety Info',
    'safety_trip_details': 'Trip Details',
    'safety_destination': 'Destination',
    'safety_expected_return_time': 'Expected Return Time',
    'safety_current_location_link': 'Current Location Link',
    'safety_last_update': 'Last update',
    'safety_get_current_location': 'Get Current Location',
    'safety_message_preview': 'Message Preview',
    'safety_share_whatsapp': 'Share via WhatsApp',
    'safety_copy_message': 'Copy Message',
    'safety_whatsapp_manual_note':
        'This message is not sent automatically. You choose the recipient in WhatsApp.',
    'safety_info_saved': 'Safety info saved successfully.',
    'safety_info_save_failed': 'Failed to save safety info.',
    'safety_required_trip_fields':
        'Please enter destination and expected return time.',
    'safety_location_added': 'Location added successfully.',
    'safety_location_failed': 'Unable to get current location.',
    'safety_message_copied': 'Message copied.',
    'safety_whatsapp_open_failed':
        'Unable to open WhatsApp. Please copy the message instead.',
    'safety_message_title': 'Smart Kashta Safety Check-in',
    'safety_message_intro':
        'I am sharing this message before my outdoor trip for safety.',
    'safety_message_expected_return': 'Expected return time',
    'safety_message_vehicle': 'Vehicle',
    'safety_message_plate_number': 'Plate number',
    'safety_message_current_location': 'Current location',
    'safety_message_last_update': 'Last update',
    'safety_message_footer':
        'If I am significantly delayed or unreachable, please try to contact me first. If there is still no response and you are concerned about my safety, please notify the relevant authorities and share these trip details with them.',
    'explore_hint': 'Place details will appear here.',
    'exploreSubtitle': 'Find warm escapes, smart picks, and nearby places.',
    'exploreSearchHint': 'Search places, activities, or regions',
    'all': 'All',
    'environmentLabel': 'Environment',
    'kashtaConditions': 'Kashta conditions',
    'openInGoogleMaps': 'Open in Google Maps',
    'rateThisPlace': 'Rate this place',
    'writeYourComment': 'Write your comment...',
    'addImageOptional': 'Add Image (Optional)',
    'submitReview': 'Submit Review',
    'averageRating': 'Average rating',
    'photos': 'Photos',
    'reviews': 'Reviews',
    'weatherLabel': 'Weather',
    'windLabel': 'Wind',
    'load_error': 'Failed to load trips',
    'no_trips': 'No trips yet. Add a new trip.',
    'new_trip': 'New Trip',
    'trip_checklist': 'Trip Checklist',
    'add_checklist_items': 'Add Checklist Items',
    'add_items': 'Add Items',
    'add_from_template': 'Add From Template',
    'added': 'Added',
    'checklist_progress': 'Checklist Progress',
    'items_completed': 'items completed',
    'checklist_item_added': 'Checklist item added',
    'no_checklist_items': 'No checklist items yet',
    'no_checklist_templates': 'No checklist templates found',
    'other': 'Other',
    'add': 'Add',
    'members': 'Members',
    'upcoming': 'Upcoming',
    'past': 'Past',
    'add_trip': 'Add Trip',
    'trip_name': 'Trip Name',
    'description': 'Description',
    'location_name': 'Location name',
    'map_link_optional': 'Map link (optional)',
    'select_group': 'Select Group',
    'sign_in_select_group': 'Sign in to select a group.',
    'link_group_later': 'You can create this trip now and link a group later.',
    'choose_date_time': 'Choose date & time',
    'date_time': 'Date & time',
    'create_trip': 'Create Trip',
    'preview': 'Preview',
    'no_group_selected': 'No group selected',
    'upcoming_trips': 'Upcoming Trips',
    'past_trips': 'Past Trips',
    'hide_past_trips': 'Hide past trips',
    'show_past_trips': 'Show past trips',
    'no_upcoming_trips': 'No upcoming trips.',
    'past_trips_hidden': 'past trips hidden',
    'past_trip_hidden': 'past trip hidden',
    'please_sign_in_view_trips': 'Please sign in to view trips.',
    'trips_index_required': 'Trips query requires a Firestore index.',
    'no_date': 'No date',
    'no_group': 'No group yet',
    'untitled_group': 'Untitled group',
    'open_checklist': 'Open Checklist',
    'view_details': 'View Details',
    'member_not_confirmed': 'member not confirmed',
    'members_not_confirmed': 'members not confirmed',
    'ready': 'Ready',
    'not_happening': 'Not happening',
    'trip_details': 'Trip Details',
    'failed_load_trip': 'Failed to load trip.',
    'trip_not_found': 'Trip not found.',
    'trip_members': 'Members',
    'no_members_yet': 'No members yet.',
    'member': 'Member',
    'please_sign_in_first': 'Please sign in first.',
    'unable_update_attendance': 'Unable to update attendance.',
    'sign_in_confirm_attendance': 'Sign in to confirm attendance.',
    'will_you_attend': 'Will you attend?',
    'you_are_going': 'You are going',
    'you_are_not_going': 'You are not going',
    'change': 'Change',
    'im_going': "I'm going",
    'not_going': 'Not going',
    'going': 'Going',
    'pending': 'Pending',
    'search_checklist_items': 'Search checklist items',
    'no_matching_items': 'No matching items',
    'undo_completion_before_release':
        'Undo completion before releasing this item.',
    'add_from_templates': 'Add from templates',
    'assign_to_me': 'Assign to me',
    'release_item': 'Release item',
    'assign_item_first': 'Assign this item to yourself first.',
    'item_assigned_to_another_member':
        'This item is assigned to another member.',
    'you': 'You',
    'jan': 'Jan',
    'feb': 'Feb',
    'mar': 'Mar',
    'apr': 'Apr',
    'may': 'May',
    'jun': 'Jun',
    'jul': 'Jul',
    'aug': 'Aug',
    'sep': 'Sep',
    'oct': 'Oct',
    'nov': 'Nov',
    'dec': 'Dec',
    'am': 'AM',
    'pm': 'PM',
    'people_count': 'People Count',
    'location_url': 'Location URL',
    'choose_trip_date': 'Choose trip date',
    'save_trip': 'Save Trip',
    'fill_all_fields': 'Fill all fields correctly',
    'save_failed': 'Failed to save trip',
    'permission_denied': 'Permission denied',
    'groups_page': 'Groups page',
    'groupsTitle': 'Groups',
    'searchGroups': 'Search groups',
    'joinGroup': 'Join Group',
    'join': 'Join',
    'newGroup': 'New Group',
    'failedToLoadGroups': 'Failed to load groups',
    'noGroupsMatchSearch': 'No groups match your search',
    'enterInvitationCode': 'Enter invitation code',
    'joinedGroup': 'Joined group',
    'alreadyGroupMember': 'You are already a member',
    'groupNotFound': 'Group not found',
    'unableToJoinGroup': 'Unable to join group',
    'no_groups_yet': 'No groups yet',
    'groups_empty_subtitle':
        'Create a group to start planning your next Kashta',
    'groupsChatEmptySubtitle':
        'Create a group to start chatting and planning together.',
    'createGroup': 'Create group',
    'createGroupTitle': 'Create Group',
    'groupName': 'Group name',
    'nameAndDescriptionRequired': 'Name and description are required.',
    'unableToCreateGroup': 'Unable to create group.',
    'chooseGroupImage': 'Choose group image',
    'checklistTripLinkOptional': 'Checklist trip link (optional)',
    'checklistTrip': 'Checklist trip',
    'leaveChecklistLinkEmpty':
        'Leave empty if you do not want to link this group to a checklist.',
    'groupDetails': 'Group Details',
    'groupChat': 'Group Chat',
    'unableToLoadGroup': 'Unable to load group.',
    'unableToLoadGroupAccess': 'Unable to load group access',
    'selectExistingTrip': 'Select existing trip',
    'createNewTrip': 'Create new trip',
    'failedToLoadTrips': 'Failed to load trips.',
    'noTripsAvailable': 'No trips available.',
    'tripLinkedToGroup': 'Trip linked to group',
    'failedToLinkTrip': 'Failed to link trip',
    'inviteMembers': 'Invite Members',
    'shareInvitationCode':
        'Share this invitation code with your friends so they can join the group.',
    'shareInvitationCodeShort': 'Share an invitation code with friends',
    'invitationCode': 'Invitation Code',
    'invitationCodeCopied': 'Invitation code copied',
    'invitationLinkCopied': 'Invitation link copied',
    'copyCode': 'Copy Code',
    'copyLink': 'Copy Link',
    'planTrip': 'Plan trip',
    'upcomingTrip': 'Upcoming Trip',
    'upcomingTripCountOne': '1 upcoming trip',
    'noDescriptionYet': 'No description yet.',
    'noUpcomingTrip': 'No upcoming trip',
    'writeMessage': 'Write a message',
    'joinGroupToChat': 'Join the group to chat',
    'seen': 'Seen',
    'sent': 'Sent',
    'sending': 'Sending',
    'unableToSendMessage': 'Unable to send message.',
    'unableToUpdateMessage': 'Unable to update message.',
    'unableToLoadMessages': 'Unable to load messages',
    'noMessagesYet': 'No messages yet. Start the conversation.',
    'pinned': 'Pinned',
    'pinnedWithMessage': 'Pinned: {message}',
    'noPinnedMessages': 'No pinned messages',
    'pin': 'Pin',
    'unpin': 'Unpin',
    'noMessagesPreview': 'No messages yet',
    'unnamedGroup': 'Unnamed Group',
    'systemCreatedGroup': '{username} created the group',
    'systemJoinedGroup': '{username} joined the group',
    'systemChecklistLinked': 'Checklist linked to this group',
    'guest_account': 'Guest account',
    'signed_in_account': 'Signed in account',
    'sign_out': 'Sign Out',
    'favorites': 'Favorites',
    'desert': 'Desert',
    'beach': 'Beach',
    'family': 'Family',
    'quiet': 'Quiet',
    'edit_profile': 'Edit Profile',
    'my_trips': 'My Trips',
    'admin_dashboard': 'Admin Dashboard',
    'coming_soon': 'Coming soon',
    'access_denied': 'Access denied',
    'pending_places': 'Pending Places',
    'waiting_for_review': 'waiting for review',
    'failed_load_moderation_dashboard': 'Failed to load moderation dashboard',
    'failed_load_pending_places': 'Failed to load pending places',
    'no_pending_places': 'No pending places',
    'approve': 'Approve',
    'reject': 'Reject',
    'type': 'Type',
    'created_by': 'Created by',
    'operation_failed': 'Operation failed',
    'choose_preferences':
        'Let us personalize your experience by asking you a few quick questions.',
    'preferred_place_type': 'Preferred place type',
    'nature': 'Nature',
    'distance_preference': 'Distance preference',
    'near': 'Near',
    'flexible': 'Flexible',
    'preferred_weather': 'Preferred weather',
    'cool': 'Cool',
    'moderate': 'Moderate',
    'warm': 'Warm',
    'preferred_activity': 'Preferred activity',
    'camping': 'Camping',
    'barbecue': 'Barbecue',
    'hiking': 'Hiking',
    'relaxing': 'Relaxing',
    'please_answer_all_questions': 'Please answer all questions',
    'continue_button': 'Continue',
    'firestore_permission_denied':
        'You do not have permission to perform this action.',
    'firestore_unauthenticated': 'Please sign in again.',
    'firestore_invalid_fields': 'Some fields are invalid.',
    'firestore_generic_error': 'Something went wrong. Please try again.',
    'checklist_linked': 'Checklist linked',
    'no_linked_trip_found': 'No linked trip found.',
    'group_trip': 'Group Trip',
    'link_to_checklist': 'Link to checklist',
    'unable_to_link_checklist': 'Unable to link checklist.',
    'no_trips_create_first': 'No trips found. Create a trip first.',
    'untitled_trip': 'Untitled trip',
  };

  static const _ar = {
    'welcome_title':
        '\u0623\u0647\u0644\u064b\u0627 \u0628\u0643 \u0641\u064a \u0643\u0634\u062a\u0629',
    'welcome_subtitle':
        '\u0627\u0643\u062a\u0634\u0641 \u0627\u0644\u0623\u0645\u0627\u0643\u0646\u060c \u062e\u0637\u0637 \u0631\u062d\u0644\u0627\u062a\u0643\u060c \u0648\u0634\u0627\u0631\u0643 \u0627\u0644\u0645\u063a\u0627\u0645\u0631\u0627\u062a.',
    'email':
        '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
    'password': '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
    'full_name':
        '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644',
    'username':
        '\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645',
    'sign_in': '\u062a\u0633\u062c\u064a\u0644 \u062f\u062e\u0648\u0644',
    'sign_up': '\u0625\u0646\u0634\u0627\u0621 \u062d\u0633\u0627\u0628',
    'continue_google':
        '\u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629 \u0639\u0628\u0631 Google',
    'sign_in_phone':
        '\u0627\u0644\u062f\u062e\u0648\u0644 \u0628\u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644',
    'continue_guest':
        '\u0627\u0644\u062f\u062e\u0648\u0644 \u0643\u0636\u064a\u0641',
    'email_password_required':
        '\u0627\u0644\u0628\u0631\u064a\u062f \u0648\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0645\u0637\u0644\u0648\u0628\u0627\u0646',
    'full_name_required':
        '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644 \u0645\u0637\u0644\u0648\u0628',
    'username_required':
        '\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0645\u0637\u0644\u0648\u0628',
    'username_taken':
        '\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645 \u0645\u0633\u062a\u062e\u062f\u0645 \u0645\u0633\u0628\u0642\u0627\u064b. \u064a\u0631\u062c\u0649 \u0627\u062e\u062a\u064a\u0627\u0631 \u0627\u0633\u0645 \u0622\u062e\u0631.',
    'email_already_registered':
        '\u0647\u0630\u0627 \u0627\u0644\u0628\u0631\u064a\u062f \u0645\u0633\u062c\u0644 \u0645\u0633\u0628\u0642\u0627\u064b. \u064a\u0631\u062c\u0649 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644.',
    'could_not_create_user_profile':
        '\u062a\u0639\u0630\u0631 \u0625\u0646\u0634\u0627\u0621 \u0645\u0644\u0641 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645. \u064a\u0631\u062c\u0649 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.',
    'phone_number': '\u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644',
    'phone_hint': '+9665XXXXXXXX',
    'phone_failed':
        '\u0641\u0634\u0644 \u062a\u0633\u062c\u064a\u0644 \u0631\u0642\u0645 \u0627\u0644\u062c\u0648\u0627\u0644',
    'sms_code': '\u0631\u0645\u0632 \u0627\u0644\u062a\u062d\u0642\u0642',
    'sms_hint': '\u0623\u062f\u062e\u0644 \u0627\u0644\u0631\u0645\u0632',
    'cancel': '\u0625\u0644\u063a\u0627\u0621',
    'confirm': '\u062a\u0623\u0643\u064a\u062f',
    'explore': '\u0627\u0633\u062a\u0643\u0634\u0627\u0641',
    'trips': '\u0631\u062d\u0644\u0627\u062a',
    'groups': '\u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0627\u062a',
    'profile': '\u0645\u0644\u0641\u064a',
    'safety_checkin': '\u0627\u0644\u0633\u0644\u0627\u0645\u0629',
    'safety_checkin_title': 'تسجيل السلامة',
    'safety_checkin_profile_subtitle':
        'جهّز وشارك تفاصيل رحلتك للسلامة.',
    'safety_my_info': 'معلومات السلامة الخاصة بي',
    'safety_name': 'الاسم',
    'safety_phone': 'رقم الجوال',
    'safety_vehicle_type': 'نوع السيارة',
    'safety_vehicle_color': 'لون السيارة',
    'safety_plate_number': 'رقم اللوحة',
    'safety_saved_info_note':
        'تُستخدم معلومات السلامة المحفوظة فقط لتجهيز رسالة السلامة بشكل أسرع.',
    'safety_save_info': 'حفظ معلومات السلامة',
    'safety_trip_details': 'تفاصيل الرحلة',
    'safety_destination': 'الوجهة',
    'safety_expected_return_time': 'وقت الرجوع المتوقع',
    'safety_current_location_link': 'رابط الموقع الحالي',
    'safety_last_update': 'آخر تحديث',
    'safety_get_current_location': 'تحديد موقعي الحالي',
    'safety_message_preview': 'معاينة الرسالة',
    'safety_share_whatsapp': 'مشاركة عبر واتساب',
    'safety_copy_message': 'نسخ الرسالة',
    'safety_whatsapp_manual_note':
        'لا يتم إرسال هذه الرسالة تلقائيًا. أنت تختار المستلم داخل واتساب.',
    'safety_info_saved': 'تم حفظ معلومات السلامة بنجاح.',
    'safety_info_save_failed': 'تعذر حفظ معلومات السلامة.',
    'safety_required_trip_fields':
        'يرجى إدخال الوجهة ووقت الرجوع المتوقع.',
    'safety_location_added': 'تمت إضافة الموقع بنجاح.',
    'safety_location_failed': 'تعذر تحديد الموقع الحالي.',
    'safety_message_copied': 'تم نسخ الرسالة.',
    'safety_whatsapp_open_failed':
        'تعذر فتح واتساب. يرجى نسخ الرسالة بدلًا من ذلك.',
    'safety_message_title': 'تسجيل السلامة من Smart Kashta',
    'safety_message_intro':
        'أشارك هذه الرسالة قبل رحلتي الخارجية لغرض السلامة.',
    'safety_message_expected_return': 'وقت الرجوع المتوقع',
    'safety_message_vehicle': 'السيارة',
    'safety_message_plate_number': 'رقم اللوحة',
    'safety_message_current_location': 'الموقع الحالي',
    'safety_message_last_update': 'آخر تحديث',
    'safety_message_footer':
        'إذا تأخرت بشكل ملحوظ أو تعذر التواصل معي، يرجى محاولة الاتصال بي أولًا. وإذا لم يكن هناك رد وما زال هناك قلق على سلامتي، يرجى إبلاغ الجهات المختصة ومشاركة تفاصيل الرحلة هذه معهم.',
    'explore_hint':
        '\u0647\u0646\u0627 \u062a\u0638\u0647\u0631 \u062a\u0641\u0627\u0635\u064a\u0644 \u0627\u0644\u0623\u0645\u0627\u0643\u0646.',
    'exploreSubtitle':
        '\u0627\u0643\u062a\u0634\u0641 \u0623\u0645\u0627\u0643\u0646 \u0645\u0646\u0627\u0633\u0628\u0629\u060c \u0648\u0627\u0642\u062a\u0631\u0627\u062d\u0627\u062a \u0630\u0643\u064a\u0629\u060c \u0648\u0645\u0648\u0627\u0642\u0639 \u0642\u0631\u064a\u0628\u0629.',
    'exploreSearchHint':
        '\u0627\u0628\u062d\u062b \u0639\u0646 \u0623\u0645\u0627\u0643\u0646 \u0623\u0648 \u0623\u0646\u0634\u0637\u0629 \u0623\u0648 \u0645\u0646\u0627\u0637\u0642',
    'all': '\u0627\u0644\u0643\u0644',
    'environmentLabel': '\u0627\u0644\u0628\u064a\u0626\u0629',
    'kashtaConditions':
        '\u062d\u0627\u0644\u0629 \u0627\u0644\u0643\u0634\u062a\u0629',
    'openInGoogleMaps':
        '\u0641\u062a\u062d \u0641\u064a \u062e\u0631\u0627\u0626\u0637 Google',
    'rateThisPlace':
        '\u0642\u064a\u0651\u0645 \u0647\u0630\u0627 \u0627\u0644\u0645\u0643\u0627\u0646',
    'writeYourComment':
        '\u0627\u0643\u062a\u0628 \u062a\u0639\u0644\u064a\u0642\u0643...',
    'addImageOptional':
        '\u0625\u0636\u0627\u0641\u0629 \u0635\u0648\u0631\u0629 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)',
    'submitReview':
        '\u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u062a\u0642\u064a\u064a\u0645',
    'averageRating':
        '\u0645\u062a\u0648\u0633\u0637 \u0627\u0644\u062a\u0642\u064a\u064a\u0645',
    'photos': '\u0627\u0644\u0635\u0648\u0631',
    'reviews': '\u0627\u0644\u0645\u0631\u0627\u062c\u0639\u0627\u062a',
    'weatherLabel': '\u0627\u0644\u0637\u0642\u0633',
    'windLabel': '\u0627\u0644\u0631\u064a\u0627\u062d',
    'load_error':
        '\u062a\u0639\u0630\u0631 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0631\u062d\u0644\u0627\u062a',
    'no_trips':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0631\u062d\u0644\u0627\u062a \u062d\u0627\u0644\u064a\u0627\u064b\u060c \u0623\u0636\u0641 \u0631\u062d\u0644\u0629 \u062c\u062f\u064a\u062f\u0629.',
    'new_trip': '\u0631\u062d\u0644\u0629 \u062c\u062f\u064a\u062f\u0629',
    'trip_checklist':
        '\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u062c\u0647\u064a\u0632 \u0644\u0644\u0631\u062d\u0644\u0629',
    'add_checklist_items':
        '\u0625\u0636\u0627\u0641\u0629 \u0639\u0646\u0627\u0635\u0631 \u0627\u0644\u0642\u0627\u0626\u0645\u0629',
    'add_items':
        '\u0625\u0636\u0627\u0641\u0629 \u0639\u0646\u0627\u0635\u0631',
    'add_from_template':
        '\u0625\u0636\u0627\u0641\u0629 \u0645\u0646 \u0627\u0644\u0642\u0627\u0644\u0628',
    'added': '\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u062a\u0647',
    'checklist_progress':
        '\u062a\u0642\u062f\u0645 \u0627\u0644\u0642\u0627\u0626\u0645\u0629',
    'items_completed':
        '\u0639\u0646\u0635\u0631 \u0645\u0643\u062a\u0645\u0644',
    'checklist_item_added':
        '\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u0629 \u0639\u0646\u0635\u0631 \u0627\u0644\u0642\u0627\u0626\u0645\u0629',
    'no_checklist_items':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0639\u0646\u0627\u0635\u0631 \u0641\u064a \u0627\u0644\u0642\u0627\u0626\u0645\u0629 \u0628\u0639\u062f',
    'no_checklist_templates':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0642\u0648\u0627\u0644\u0628 \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u062c\u0647\u064a\u0632',
    'other': '\u0623\u062e\u0631\u0649',
    'add': '\u0625\u0636\u0627\u0641\u0629',
    'members': '\u0623\u0639\u0636\u0627\u0621',
    'upcoming': '\u0627\u0644\u0642\u0627\u062f\u0645\u0629',
    'past': '\u0627\u0644\u0633\u0627\u0628\u0642\u0629',
    'add_trip': '\u0625\u0636\u0627\u0641\u0629 \u0631\u062d\u0644\u0629',
    'trip_name': '\u0627\u0633\u0645 \u0627\u0644\u0631\u062d\u0644\u0629',
    'description': '\u0648\u0635\u0641',
    'location_name': '\u0627\u0633\u0645 \u0627\u0644\u0645\u0648\u0642\u0639',
    'map_link_optional':
        '\u0631\u0627\u0628\u0637 \u0627\u0644\u062e\u0631\u064a\u0637\u0629 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)',
    'select_group':
        '\u0627\u062e\u062a\u0631 \u0645\u062c\u0645\u0648\u0639\u0629',
    'sign_in_select_group':
        '\u0633\u062c\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0644\u0627\u062e\u062a\u064a\u0627\u0631 \u0645\u062c\u0645\u0648\u0639\u0629.',
    'link_group_later':
        '\u064a\u0645\u0643\u0646\u0643 \u0625\u0646\u0634\u0627\u0621 \u0647\u0630\u0647 \u0627\u0644\u0631\u062d\u0644\u0629 \u0627\u0644\u0622\u0646 \u0648\u0631\u0628\u0637 \u0645\u062c\u0645\u0648\u0639\u0629 \u0644\u0627\u062d\u0642\u0627\u064b.',
    'choose_date_time':
        '\u0627\u062e\u062a\u0631 \u0627\u0644\u062a\u0627\u0631\u064a\u062e \u0648\u0627\u0644\u0648\u0642\u062a',
    'date_time':
        '\u0627\u0644\u062a\u0627\u0631\u064a\u062e \u0648\u0627\u0644\u0648\u0642\u062a',
    'create_trip': '\u0625\u0646\u0634\u0627\u0621 \u0631\u062d\u0644\u0629',
    'preview': '\u0645\u0639\u0627\u064a\u0646\u0629',
    'no_group_selected':
        '\u0644\u0645 \u064a\u062a\u0645 \u0627\u062e\u062a\u064a\u0627\u0631 \u0645\u062c\u0645\u0648\u0639\u0629',
    'upcoming_trips':
        '\u0627\u0644\u0631\u062d\u0644\u0627\u062a \u0627\u0644\u0642\u0627\u062f\u0645\u0629',
    'past_trips':
        '\u0627\u0644\u0631\u062d\u0644\u0627\u062a \u0627\u0644\u0633\u0627\u0628\u0642\u0629',
    'hide_past_trips':
        '\u0625\u062e\u0641\u0627\u0621 \u0627\u0644\u0631\u062d\u0644\u0627\u062a \u0627\u0644\u0633\u0627\u0628\u0642\u0629',
    'show_past_trips':
        '\u0639\u0631\u0636 \u0627\u0644\u0631\u062d\u0644\u0627\u062a \u0627\u0644\u0633\u0627\u0628\u0642\u0629',
    'no_upcoming_trips':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0631\u062d\u0644\u0627\u062a \u0642\u0627\u062f\u0645\u0629.',
    'past_trips_hidden':
        '\u0631\u062d\u0644\u0627\u062a \u0633\u0627\u0628\u0642\u0629 \u0645\u062e\u0641\u064a\u0629',
    'past_trip_hidden':
        '\u0631\u062d\u0644\u0629 \u0633\u0627\u0628\u0642\u0629 \u0645\u062e\u0641\u064a\u0629',
    'please_sign_in_view_trips':
        '\u064a\u0631\u062c\u0649 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0644\u0639\u0631\u0636 \u0627\u0644\u0631\u062d\u0644\u0627\u062a.',
    'trips_index_required':
        '\u064a\u062a\u0637\u0644\u0628 \u0627\u0633\u062a\u0639\u0644\u0627\u0645 \u0627\u0644\u0631\u062d\u0644\u0627\u062a \u0641\u0647\u0631\u0633 Firestore.',
    'no_date':
        '\u0644\u0627 \u064a\u0648\u062c\u062f \u062a\u0627\u0631\u064a\u062e',
    'no_group':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u062c\u0645\u0648\u0639\u0629 \u0628\u0639\u062f',
    'untitled_group':
        '\u0645\u062c\u0645\u0648\u0639\u0629 \u0628\u0644\u0627 \u0627\u0633\u0645',
    'open_checklist':
        '\u0641\u062a\u062d \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u062c\u0647\u064a\u0632',
    'view_details':
        '\u0639\u0631\u0636 \u0627\u0644\u062a\u0641\u0627\u0635\u064a\u0644',
    'member_not_confirmed':
        '\u0639\u0636\u0648 \u0644\u0645 \u064a\u0624\u0643\u062f',
    'members_not_confirmed':
        '\u0623\u0639\u0636\u0627\u0621 \u0644\u0645 \u064a\u0624\u0643\u062f\u0648\u0627',
    'ready': '\u062c\u0627\u0647\u0632\u0629',
    'not_happening': '\u0644\u0646 \u062a\u062a\u0645',
    'trip_details':
        '\u062a\u0641\u0627\u0635\u064a\u0644 \u0627\u0644\u0631\u062d\u0644\u0629',
    'failed_load_trip':
        '\u0641\u0634\u0644 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0631\u062d\u0644\u0629.',
    'trip_not_found':
        '\u0644\u0645 \u064a\u062a\u0645 \u0627\u0644\u0639\u062b\u0648\u0631 \u0639\u0644\u0649 \u0627\u0644\u0631\u062d\u0644\u0629.',
    'trip_members': '\u0627\u0644\u0623\u0639\u0636\u0627\u0621',
    'no_members_yet':
        '\u0644\u0627 \u064a\u0648\u062c\u062f \u0623\u0639\u0636\u0627\u0621 \u0628\u0639\u062f.',
    'member': '\u0639\u0636\u0648',
    'please_sign_in_first':
        '\u064a\u0631\u062c\u0649 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0623\u0648\u0644\u0627\u064b.',
    'unable_update_attendance':
        '\u062a\u0639\u0630\u0631 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u062d\u0636\u0648\u0631.',
    'sign_in_confirm_attendance':
        '\u0633\u062c\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0644\u062a\u0623\u0643\u064a\u062f \u0627\u0644\u062d\u0636\u0648\u0631.',
    'will_you_attend': '\u0647\u0644 \u0633\u062a\u062d\u0636\u0631\u061f',
    'you_are_going': '\u0623\u0646\u062a \u0633\u062a\u062d\u0636\u0631',
    'you_are_not_going':
        '\u0623\u0646\u062a \u0644\u0646 \u062a\u062d\u0636\u0631',
    'change': '\u062a\u063a\u064a\u064a\u0631',
    'im_going': '\u0633\u0623\u062d\u0636\u0631',
    'not_going': '\u0644\u0646 \u0623\u062d\u0636\u0631',
    'going': '\u0633\u064a\u062d\u0636\u0631',
    'pending':
        '\u0642\u064a\u062f \u0627\u0644\u0627\u0646\u062a\u0638\u0627\u0631',
    'search_checklist_items':
        '\u0627\u0628\u062d\u062b \u0641\u064a \u0639\u0646\u0627\u0635\u0631 \u0627\u0644\u0642\u0627\u0626\u0645\u0629',
    'no_matching_items':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0639\u0646\u0627\u0635\u0631 \u0645\u0637\u0627\u0628\u0642\u0629',
    'undo_completion_before_release':
        '\u0623\u0644\u063a \u0625\u0643\u0645\u0627\u0644 \u0627\u0644\u0639\u0646\u0635\u0631 \u0642\u0628\u0644 \u062a\u062d\u0631\u064a\u0631\u0647.',
    'add_from_templates':
        '\u0625\u0636\u0627\u0641\u0629 \u0645\u0646 \u0627\u0644\u0642\u0648\u0627\u0644\u0628',
    'assign_to_me': '\u0625\u0633\u0646\u0627\u062f \u0625\u0644\u064a',
    'release_item':
        '\u062a\u062d\u0631\u064a\u0631 \u0627\u0644\u0639\u0646\u0635\u0631',
    'assign_item_first':
        '\u0623\u0633\u0646\u062f \u0647\u0630\u0627 \u0627\u0644\u0639\u0646\u0635\u0631 \u0625\u0644\u064a\u0643 \u0623\u0648\u0644\u0627\u064b.',
    'item_assigned_to_another_member':
        '\u0647\u0630\u0627 \u0627\u0644\u0639\u0646\u0635\u0631 \u0645\u0633\u0646\u062f \u0644\u0639\u0636\u0648 \u0622\u062e\u0631.',
    'you': '\u0623\u0646\u062a',
    'jan': '\u064a\u0646\u0627\u064a\u0631',
    'feb': '\u0641\u0628\u0631\u0627\u064a\u0631',
    'mar': '\u0645\u0627\u0631\u0633',
    'apr': '\u0623\u0628\u0631\u064a\u0644',
    'may': '\u0645\u0627\u064a\u0648',
    'jun': '\u064a\u0648\u0646\u064a\u0648',
    'jul': '\u064a\u0648\u0644\u064a\u0648',
    'aug': '\u0623\u063a\u0633\u0637\u0633',
    'sep': '\u0633\u0628\u062a\u0645\u0628\u0631',
    'oct': '\u0623\u0643\u062a\u0648\u0628\u0631',
    'nov': '\u0646\u0648\u0641\u0645\u0628\u0631',
    'dec': '\u062f\u064a\u0633\u0645\u0628\u0631',
    'am': '\u0635',
    'pm': '\u0645',
    'people_count':
        '\u0639\u062f\u062f \u0627\u0644\u0623\u0634\u062e\u0627\u0635',
    'location_url':
        '\u0631\u0627\u0628\u0637 \u0627\u0644\u0645\u0648\u0642\u0639',
    'choose_trip_date':
        '\u0627\u062e\u062a\u0631 \u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0631\u062d\u0644\u0629',
    'save_trip': '\u062d\u0641\u0638 \u0627\u0644\u0631\u062d\u0644\u0629',
    'fill_all_fields':
        '\u0627\u0645\u0644\u0623 \u062c\u0645\u064a\u0639 \u0627\u0644\u062d\u0642\u0648\u0644 \u0628\u0634\u0643\u0644 \u0635\u062d\u064a\u062d',
    'save_failed':
        '\u0641\u0634\u0644 \u062d\u0641\u0638 \u0627\u0644\u0631\u062d\u0644\u0629',
    'permission_denied':
        '\u0644\u0627 \u062a\u0645\u0644\u0643 \u0635\u0644\u0627\u062d\u064a\u0629 \u0644\u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621',
    'groups_page':
        '\u0635\u0641\u062d\u0629 \u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0627\u062a',
    'groupsTitle': 'المجموعات',
    'searchGroups': 'ابحث في المجموعات',
    'joinGroup': 'انضم إلى مجموعة',
    'join': 'انضمام',
    'newGroup': 'مجموعة جديدة',
    'failedToLoadGroups': 'تعذر تحميل المجموعات',
    'noGroupsMatchSearch': 'لا توجد مجموعات تطابق البحث',
    'enterInvitationCode': 'أدخل رمز الدعوة',
    'joinedGroup': 'تم الانضمام إلى المجموعة',
    'alreadyGroupMember': 'أنت عضو في هذه المجموعة بالفعل',
    'groupNotFound': 'لم يتم العثور على المجموعة',
    'unableToJoinGroup': 'تعذر الانضمام إلى المجموعة',
    'no_groups_yet':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u062c\u0645\u0648\u0639\u0627\u062a \u0628\u0639\u062f',
    'groups_empty_subtitle':
        '\u0623\u0646\u0634\u0626 \u0645\u062c\u0645\u0648\u0639\u0629 \u0644\u0628\u062f\u0621 \u0627\u0644\u062a\u062e\u0637\u064a\u0637 \u0644\u0643\u0634\u062a\u062a\u0643 \u0627\u0644\u0642\u0627\u062f\u0645\u0629',
    'groupsChatEmptySubtitle': 'أنشئ مجموعة لبدء الدردشة والتخطيط معا.',
    'createGroup': 'إنشاء مجموعة',
    'createGroupTitle': 'إنشاء مجموعة',
    'groupName': 'اسم المجموعة',
    'nameAndDescriptionRequired': 'اسم المجموعة والوصف مطلوبان.',
    'unableToCreateGroup': 'تعذر إنشاء المجموعة.',
    'chooseGroupImage': 'اختر صورة المجموعة',
    'checklistTripLinkOptional': 'ربط رحلة بقائمة التجهيز (اختياري)',
    'checklistTrip': 'رحلة قائمة التجهيز',
    'leaveChecklistLinkEmpty':
        'اتركه فارغا إذا كنت لا تريد ربط هذه المجموعة بقائمة تجهيز.',
    'groupDetails': 'تفاصيل المجموعة',
    'groupChat': 'دردشة المجموعة',
    'unableToLoadGroup': 'تعذر تحميل المجموعة.',
    'unableToLoadGroupAccess': 'تعذر تحميل صلاحية الوصول إلى المجموعة',
    'selectExistingTrip': 'اختر رحلة موجودة',
    'createNewTrip': 'إنشاء رحلة جديدة',
    'failedToLoadTrips': 'تعذر تحميل الرحلات.',
    'noTripsAvailable': 'لا توجد رحلات متاحة.',
    'tripLinkedToGroup': 'تم ربط الرحلة بالمجموعة',
    'failedToLinkTrip': 'تعذر ربط الرحلة',
    'inviteMembers': 'دعوة الأعضاء',
    'shareInvitationCode':
        'شارك رمز الدعوة هذا مع أصدقائك لينضموا إلى المجموعة.',
    'shareInvitationCodeShort': 'شارك رمز دعوة مع الأصدقاء',
    'invitationCode': 'رمز الدعوة',
    'invitationCodeCopied': 'تم نسخ رمز الدعوة',
    'invitationLinkCopied': 'تم نسخ رابط الدعوة',
    'copyCode': 'نسخ الرمز',
    'copyLink': 'نسخ الرابط',
    'planTrip': 'تخطيط رحلة',
    'upcomingTrip': 'الرحلة القادمة',
    'upcomingTripCountOne': 'رحلة قادمة واحدة',
    'noDescriptionYet': 'لا يوجد وصف بعد.',
    'noUpcomingTrip': 'لا توجد رحلة قادمة',
    'writeMessage': 'اكتب رسالة',
    'joinGroupToChat': 'انضم إلى المجموعة للدردشة',
    'seen': 'تمت المشاهدة',
    'sent': 'تم الإرسال',
    'sending': 'جار الإرسال',
    'unableToSendMessage': 'تعذر إرسال الرسالة.',
    'unableToUpdateMessage': 'تعذر تحديث الرسالة.',
    'unableToLoadMessages': 'تعذر تحميل الرسائل',
    'noMessagesYet': 'لا توجد رسائل بعد. ابدأ المحادثة.',
    'pinned': 'مثبتة',
    'pinnedWithMessage': 'مثبتة: {message}',
    'noPinnedMessages': 'لا توجد رسائل مثبتة',
    'pin': 'تثبيت',
    'unpin': 'إلغاء التثبيت',
    'noMessagesPreview': 'لا توجد رسائل بعد',
    'unnamedGroup': 'مجموعة بلا اسم',
    'systemCreatedGroup': 'أنشأ {username} المجموعة',
    'systemJoinedGroup': 'انضم {username} إلى المجموعة',
    'systemChecklistLinked': 'تم ربط قائمة التجهيز بهذه المجموعة',
    'guest_account': '\u062d\u0633\u0627\u0628 \u0636\u064a\u0641',
    'signed_in_account': '\u062d\u0633\u0627\u0628 \u0645\u0633\u062c\u0644',
    'sign_out': '\u062a\u0633\u062c\u064a\u0644 \u062e\u0631\u0648\u062c',
    'favorites': '\u0627\u0644\u0645\u0641\u0636\u0644\u0629',
    'desert': '\u0635\u062d\u0631\u0627\u0621',
    'beach': '\u0634\u0627\u0637\u0626',
    'family': '\u0639\u0627\u0626\u0644\u064a',
    'quiet': '\u0647\u0627\u062f\u0626',
    'edit_profile':
        '\u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u0644\u0641',
    'my_trips': '\u0631\u062d\u0644\u0627\u062a\u064a',
    'admin_dashboard':
        '\u0644\u0648\u062d\u0629 \u0627\u0644\u0645\u0634\u0631\u0641',
    'coming_soon': '\u0642\u0631\u064a\u0628\u0627\u064b',
    'access_denied': '\u0631\u0641\u0636 \u0627\u0644\u0648\u0635\u0648\u0644',
    'pending_places':
        '\u0627\u0644\u0623\u0645\u0627\u0643\u0646 \u0627\u0644\u0645\u0639\u0644\u0642\u0629',
    'waiting_for_review':
        '\u0628\u0627\u0646\u062a\u0638\u0627\u0631 \u0627\u0644\u0645\u0631\u0627\u062c\u0639\u0629',
    'failed_load_moderation_dashboard':
        '\u0641\u0634\u0644 \u062a\u062d\u0645\u064a\u0644 \u0644\u0648\u062d\u0629 \u0627\u0644\u0645\u0631\u0627\u062c\u0639\u0629',
    'failed_load_pending_places':
        '\u0641\u0634\u0644 \u062a\u062d\u0645\u064a\u0644 \u0627\u0644\u0623\u0645\u0627\u0643\u0646 \u0627\u0644\u0645\u0639\u0644\u0642\u0629',
    'no_pending_places':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0623\u0645\u0627\u0643\u0646 \u0645\u0639\u0644\u0642\u0629',
    'approve': '\u0645\u0648\u0627\u0641\u0642\u0629',
    'reject': '\u0631\u0641\u0636',
    'type': '\u0627\u0644\u0646\u0648\u0639',
    'created_by': '\u0623\u0646\u0634\u0623\u0647',
    'operation_failed':
        '\u0641\u0634\u0644\u062a \u0627\u0644\u0639\u0645\u0644\u064a\u0629',
    'choose_preferences':
        '\u062f\u0639\u0646\u0627 \u0646\u062e\u0635\u0635 \u062a\u062c\u0631\u0628\u062a\u0643 \u0628\u0637\u0631\u062d \u0628\u0636\u0639\u0629 \u0623\u0633\u0626\u0644\u0629 \u0633\u0631\u064a\u0639\u0629.',
    'preferred_place_type':
        '\u0646\u0648\u0639 \u0627\u0644\u0645\u0643\u0627\u0646 \u0627\u0644\u0645\u0641\u0636\u0644',
    'nature': '\u0637\u0628\u064a\u0639\u0629',
    'distance_preference':
        '\u062a\u0641\u0636\u064a\u0644 \u0627\u0644\u0645\u0633\u0627\u0641\u0629',
    'near': '\u0642\u0631\u064a\u0628',
    'flexible': '\u0645\u0631\u0646',
    'preferred_weather':
        '\u0627\u0644\u0637\u0642\u0633 \u0627\u0644\u0645\u0641\u0636\u0644',
    'cool': '\u0628\u0627\u0631\u062f',
    'moderate': '\u0645\u0639\u062a\u062f\u0644',
    'warm': '\u062f\u0627\u0641\u0626',
    'preferred_activity':
        '\u0627\u0644\u0646\u0634\u0627\u0637 \u0627\u0644\u0645\u0641\u0636\u0644',
    'camping': '\u062a\u062e\u064a\u064a\u0645',
    'barbecue': '\u0634\u0648\u0627\u0621',
    'hiking': '\u0645\u0634\u064a',
    'relaxing': '\u0627\u0633\u062a\u0631\u062e\u0627\u0621',
    'please_answer_all_questions':
        '\u064a\u0631\u062c\u0649 \u0627\u0644\u0625\u062c\u0627\u0628\u0629 \u0639\u0644\u0649 \u062c\u0645\u064a\u0639 \u0627\u0644\u0623\u0633\u0626\u0644\u0629',
    'continue_button': '\u0645\u062a\u0627\u0628\u0639\u0629',
    'firestore_permission_denied':
        '\u0644\u0627 \u062a\u0645\u0644\u0643 \u0635\u0644\u0627\u062d\u064a\u0629 \u0644\u062a\u0646\u0641\u064a\u0630 \u0647\u0630\u0627 \u0627\u0644\u0625\u062c\u0631\u0627\u0621.',
    'firestore_unauthenticated':
        '\u064a\u0631\u062c\u0649 \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.',
    'firestore_invalid_fields':
        '\u0628\u0639\u0636 \u0627\u0644\u062d\u0642\u0648\u0644 \u063a\u064a\u0631 \u0635\u062d\u064a\u062d\u0629.',
    'firestore_generic_error':
        '\u062d\u062f\u062b \u062e\u0637\u0623. \u064a\u0631\u062c\u0649 \u0627\u0644\u0645\u062d\u0627\u0648\u0644\u0629 \u0645\u0631\u0629 \u0623\u062e\u0631\u0649.',
    'checklist_linked':
        '\u062a\u0645 \u0631\u0628\u0637 \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u062c\u0647\u064a\u0632',
    'no_linked_trip_found':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0631\u062d\u0644\u0629 \u0645\u0631\u062a\u0628\u0637\u0629.',
    'group_trip':
        '\u0631\u062d\u0644\u0629 \u0627\u0644\u0645\u062c\u0645\u0648\u0639\u0629',
    'link_to_checklist':
        '\u0631\u0628\u0637 \u0628\u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u062c\u0647\u064a\u0632',
    'unable_to_link_checklist':
        '\u062a\u0639\u0630\u0631 \u0631\u0628\u0637 \u0642\u0627\u0626\u0645\u0629 \u0627\u0644\u062a\u062c\u0647\u064a\u0632.',
    'no_trips_create_first':
        '\u0644\u0627 \u062a\u0648\u062c\u062f \u0631\u062d\u0644\u0627\u062a. \u0623\u0646\u0634\u0626 \u0631\u062d\u0644\u0629 \u0623\u0648\u0644\u0627\u064b.',
    'untitled_trip':
        '\u0631\u062d\u0644\u0629 \u0628\u0644\u0627 \u0627\u0633\u0645',
  };

  String t(String key) {
    final map = language == AppLanguage.en ? _en : _ar;
    return map[key] ?? key;
  }
}
