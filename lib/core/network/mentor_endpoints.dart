class MentorEndpointsUrls {
  static const String apiUrl = 'api/';
  static const String userUrl = '${apiUrl}users/';

  /// Mentor
  static const String get_banners = "${apiUrl}banners";
  static const String get_sessions = "${userUrl}sessions/upcoming";
  static const String get_sessions_details = "${userUrl}sessions";
  static const String sessions_cancelled = "${userUrl}session/cancel";
  static const String get_coinshistory = "${apiUrl}users/mentor/coin-history";
  static const String mentor_profile = "${userUrl}mentor/profile";
  static const String mentor_profile_update = "${userUrl}mentor/profile/update";
  static const String feedback = "${userUrl}mentors/feedback-ui";
  static const String mentees = "${userUrl}mentees-with-sessions";
  static const String report_mentee = "${userUrl}mentor-reports";
  static const String mymenteelist = "${userUrl}my-mentees";
  static const String mentorinfo = "${userUrl}/info";
  static const String add_mentor_availability =
      "${userUrl}/add-mentor-availability";
  static const String mentor_availability_slots =
      "${userUrl}mentor/recent-slots";
  static const String approved_expertises =
      "${userUrl}/mentor/expertise/details";
  static const String pending_expertises =
      "${userUrl}/mentor/new-expertise-requests";
  static const String rejected_expertises =
      "${userUrl}/mentor/new-expertise-requests";
  static const String update_expertises = "${userUrl}/mentor/expertise/update";
  static const String non_attached_expertises =
      "${userUrl}/mentor/not-attached-expertise";
  static const String mentor_reports = "${userUrl}/mentor-reports";
  static const String new_expertise_request =
      "${userUrl}/mentor/new-expertise-request";
  static const String comments = "${userUrl}/communities/comments";
  static const String reviews = "${userUrl}/mentors/reviews/";
  static const String session_complete = "${userUrl}/sessions/complete";
  static const String mentor_earnings = "${userUrl}/mentor-earnings";
  static const String coupon_categories = "${userUrl}/coupon/categories";
  static const String coupon_list = "${userUrl}/coupons";
  static const String coupon_details = "${userUrl}/show/coupon";
  static const String buy_coupon = "${userUrl}/buy/coupon";
  static const String redeemedCoupons = "${userUrl}/user-coupons";
}
