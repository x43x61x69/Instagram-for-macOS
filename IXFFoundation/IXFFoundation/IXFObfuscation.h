//
//  IXFObfuscation.h
//  IXFFoundation
//
//  Copyright (C) 2016  Zhi-Wei Cai. (@x43x61x69)
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//

#ifndef IXFObfuscation_h
#define IXFObfuscation_h

// Key

// Instagram Signature
// 9.2.5  : 313402966dbce954860042c7d18f898a4290c833ced8c1913866fdb89d8a9562
// 9.2.0  : 012a54f51c49aa8c5c322416ab1410909add32c966bbaa0fe3dc58ac43fd7ede
// 9.1.5  : af0431ace409e957498c6050e2299baa829014a781905eef3fc94139151e5d38
// 9.0.1  : 96724bcbd4fb3e608074e185f2d4f119156fcca061692a4a1db1c7bf142d3e22
// 9.0.0  : 5519c493fc0e2d56355621cf0d4485611869067c7e26f89e946070e3c526df7d
// 8.5.2  : 3e0fbc3ab2b2a6b3dbd5f5303dc26cb8d39636291ea9da820283a275d070bd98
// 8.5.1  : b5d839444818714bdab3e288e6da9b515f85b000b6e6b452552bfd399cb56cf0
// 8.4.0  : 3d3d669cedc38f2ea7d198840e0648db3738224a0f661aa6a2c1e77dfa964a1e
// 8.3.0  : 383b229f986bfecebd281ec158a74f66e046c3539004571d6db38bd697a33b93
// 8.2.0  : 55e91155636eaa89ba5ed619eb4645a4daf1103f2161dbfe6fd94d5ea7716095
// 8.1.0  : 49b31a1b3611aa1794d2c7678dc2402010d9d6406fb522ae0097fd4cffbd71b7
// 8.0.0  : 9b3b9e55988c954e51477da115c58ae82dcae7ac01c735b4443a3c5923cb593a
// 7.21.1 : a81ad189089eccec622413139674309fea4d7563b98d99c2803578e32bf2456c
// 7.20.0 : 1ab726ef0eacca92494ef0b5949791c0b684fbd9af12a27edf7eeb97b89eb2cf
// 7.19.1 : 8082724c0ba508df900162dfe68ecb3c435873f595df87a8e19230f1fa4f6e13
// 7.19.0 : 9fca90d84e8e0f372a126ba03a22418d0836ef126ed7a538429025e791799e38

#define kSignature @"313402966dbce954860042c7d18f898a4290c833ced8c1913866fdb89d8a9562"

#define kSignatureMajor 9
#define kSignatureMinor 2
#define kSignatureRev   5
#define kSignatureVer   4

// Strings
#define kHTTPUserAgent                  @"User-Agent"
#define kHTTPContentType                @"Content-Type"
#define kHTTPApplicationURLEncoded      @"application/x-www-form-urlencoded"
#define kHTTPApplicationOctectStream    @"application/octet-stream"
#define kHTTPMethodPOST                 @"POST"

// URL
#define kAPIDoamin                  @"i.instagram.com"
#define kAPIBaseURL                 @"https://" kAPIDoamin "/api/v1"
#define kIXFChallengeFormat         @"/si/fetch_headers/?challenge_type=signup&guid="
#define kIXFLogin                   @"/accounts/login/"
#define kIXFLogout                  @"/accounts/logout/"

// Misc
//#define kIXFSignFormat              @"ig_sig_key_version=%lu&signed_body=%@.%@"
#define kIXFig_sig_key_version      @"ig_sig_key_version="
#define kIXFsigned_body             @"&signed_body="
#define kIXFCsrftoken               @"csrftoken"
#define kIXFDs_User                 @"ds_user"
#define kIXFMessage                 @"message"
#define kIXFStatus                  @"status"
#define kIXFResults                 @"results"
#define kIXFUsers                   @"users"
#define kIXFOK                      @"ok"

#define kIXFCheckpoint_Required     @"checkpoint_required"
#define kIXFCheckpoint_Url          @"checkpoint_url"
#define kIXFLogin_Required          @"login_required"
#define kIXFUsername                @"username"
#define kIXFPassword                @"password"
#define kIXFGuid                    @"guid"
#define kIXFDevice_id               @"device_id"
#define kIXFlogin_attempt_count     @"login_attempt_count"
#define kIXFlogged_in_user          @"logged_in_user"
#define kIXFpk                      @"pk"
#define kIXFfull_name               @"full_name"
#define kIXFis_private              @"is_private"
#define kIXFhas_anonymous_profile   @"has_anonymous_profile_picture"
#define kIXFprofile_pic_url         @"profile_pic_url"
#define kIXFis_verified             @"is_verified"
#define kIXFContent_Disposition     @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n"
#define kIXFContent_Disposition_FN  @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n"
#define kIXFContent_Type            @"Content-Type: %@\r\n\r\n"

#endif /* IXFObfuscation_h */
