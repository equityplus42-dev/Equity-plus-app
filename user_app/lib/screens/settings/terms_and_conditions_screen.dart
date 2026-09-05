import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedSectionIndex = -1;

  final List<_TermSection> _sections = [
    _TermSection(
      title: '1. PREAMBLE, PLATFORM IDENTITY & DEFINITIONS',
      content: '''
1.1 ACCEPTANCE OF TERMS AND BINDING SERVICE AGREEMENT
Welcome to Vridhi Network (hereinafter referred to as "Platform", "Vridhi", "We", "Us", or "Our"), operated in conjunction with the Equity Plus digital network infrastructure. By downloading, installing, accessing, browsing, registering an account on, or utilizing any services provided through the Vridhi User Mobile Application or affiliated web domains (including but not limited to https://vridhi-network-app.vercel.app), you ("User", "You", or "Your") explicitly acknowledge, represent, and warrant that you have read, understood, and agreed to be legally bound by these Terms and Conditions ("Terms", "Agreement"), alongside our Privacy Policy, Refund Policy, and Disclaimer Policy. If you do not agree with any portion of these Terms, you are strictly prohibited from accessing or using the Platform and must immediately uninstall the application and terminate all associated sessions.

1.2 PLATFORM OPERATIONAL ARCHITECTURE
Vridhi Network functions as a hybrid digital platform integrating proprietary video-based educational content distribution, digital learning snapshot allocation, structured referral link marketing, and multi-tier affiliate reward mechanisms. The Platform utilizes secure cloud computing, automated IP-based deferred referral attribution, encrypted data storage, and integrated payment gateway solutions (such as Razorpay) to deliver a seamless, high-integrity digital learning environment.

1.3 FORMAL LEGAL DEFINITIONS
For the purposes of this Agreement, the following capitalized terms shall have the exact meanings set forth below:
(a) "Account" means a unique, personalized digital membership created by an individual user upon completing the registration process and completing mandatory identity and payment verifications.
(b) "Admin" or "Administrator" refers to authorized personnel governing the Platform, managing user approvals, content releases, language assignments, payout disbursements, and system security.
(c) "Referral Code" means a unique alphanumeric identifier assigned to a registered user or administrator (e.g., "ABC12345" or "DEVREF2026") utilized to attribute downline invitations.
(d) "Deferred Referral System" refers to the automated, multi-layered attribution framework combining URL parameter parsing, device clipboard inspection, and IPv4 /24 subnet fallback matching to attribute app installations occurring post-link click.
(e) "Content Snapshot" means the specific curated package of educational videos assigned to a user based on their selected preferred language.
(f) "Watch Duration" means the exact cumulative seconds of video content played by a user as recorded by automated backend playback heartbeat telemetry.
(g) "25% Watch Limit" means the strict legal cutoff threshold calculated as twenty-five percent (25.0%) of the total cumulative duration of all videos contained within a user's assigned Content Snapshot.
(h) "30-Day Window" means the continuous calendar period of thirty (30) consecutive 24-hour days (720 total hours) initiating from the exact timestamp of successful account payment or activation.
(i) "KYC Verification" means the statutory identity verification process requiring submission of a valid Indian Permanent Account Number (PAN) and Aadhaar Card details.
(j) "Downline Network" means the structured hierarchy of users who registered using your referral code (Tier 1 Direct) or through your direct referrals (Tier 2 and Tier 3 Indirect).

1.4 BINDING AMENDMENTS AND MODIFICATIONS
Vridhi Network reserves the absolute right, at its sole discretion, to revise, modify, amend, add, or remove any portion of these Terms at any time without prior individual notice. Any modifications shall become immediately effective upon publication on the Platform. Your continued use of the Platform following the posting of revised Terms constitutes your explicit acceptance of such changes. You are advised to review these Terms periodically to remain informed of all binding updates.
''',
    ),
    _TermSection(
      title: '2. ACCOUNT REGISTRATION, KYC & ELIGIBILITY',
      content: '''
2.1 ELIGIBILITY CRITERIA AND AGE MANDATE
To register, access, or utilize the Vridhi Network, you must be a natural person who is at least eighteen (18) years of age or the legal age of majority in your jurisdiction of residence, whichever is higher. By registering an account, you represent and warrant that you possess the full legal right, authority, and capacity to enter into this legal agreement and comply with all applicable terms, conditions, obligations, and restrictions set forth herein.

2.2 ACCURACY OF REGISTRATION DATA
During the registration process, you agree to provide true, accurate, current, and complete information, including your full legal first name, last name, valid email address, mobile phone number, preferred primary language, and a valid referral code. You agree to promptly update your account profile information whenever changes occur to maintain its absolute accuracy. Providing false, misleading, or deceptive information constitutes a material breach of this Agreement and will result in immediate account termination, forfeiture of accrued referral points, and potential legal action under applicable laws.

2.3 MANDATORY KYC VERIFICATION PROTOCOL
In compliance with anti-money laundering (AML), Prevention of Money Laundering Act (PMLA), statutory tax regulations, and Financial Intelligence Unit (FIU) guidelines under Indian law, all users participating in reward withdrawals, affiliate disbursements, or formal platform operations must successfully complete Know Your Customer (KYC) verification.
(a) Required Documents: You must submit your official Permanent Account Number (PAN) and Aadhaar Card number along with verified front/back document images.
(b) PAN & Aadhaar Validation: Submitted details are cross-referenced with government databases. Any mismatch between your registered profile name and PAN card name will cause immediate KYC rejection.
(c) Restriction on Unverified Accounts: Accounts failing to complete KYC verification within thirty (30) days of initial registration shall remain restricted from performing withdrawal requests, transferring referral points, or receiving affiliate disbursements.

2.4 PREFERRED LANGUAGE ASSIGNMENT AND SNAPSHOT REGIME
Upon registration, you must explicitly select your preferred primary language (e.g., English, Hindi, Bengali, etc.). Your selection determines your assigned Content Snapshot.
(a) Language Change Requests: Users may submit a formal request to change their assigned language via the Application interface. All language change requests are subject to manual administrative review and approval.
(b) Effect of Language Change: Approving a language change replaces your current Content Snapshot with a new snapshot in the requested language. However, cumulative watch history and total watched duration recorded under your previous snapshot remain permanently logged in backend telemetry and will be factored into all refund eligibility calculations.

2.5 SINGLE ACCOUNT POLICY AND PROHIBITION OF DUPLICATION
Each individual user is strictly permitted to register and operate exactly one (1) active Vridhi Network account. Registering multiple accounts using different email addresses, altered phone numbers, proxy identities, or family member credentials to manipulate referral rewards, bypass 25% watch limits, or exploit platform bonuses is strictly prohibited. Any detection of account duplication, shared credentials, or synthetic identity creation will trigger an immediate permanent ban on all associated accounts and immediate forfeiture of all balances and pending payouts.
''',
    ),
    _TermSection(
      title: '3. REFERRAL NETWORK, DEFERRED LINK ATTRIBUTION & REWARDS',
      content: '''
3.1 REFERRAL LINK GENERATION AND SHARING
Every registered user is issued a unique Referral Code and an automated shareable URL (formatted as https://vridhi-network-app.vercel.app/download?ref=YOUR_CODE). You are granted a revocable, non-exclusive, non-transferable right to share your referral link with personal acquaintances, social media networks, and legal promotional channels, provided such sharing complies with all anti-spam regulations and platform guidelines.

3.2 DEFERRED REFERRAL ATTRIBUTION PIPELINE
To ensure 100% accurate referral attribution across diverse Android devices, mobile browsers, and app store download flows, Vridhi Network employs a state-of-the-art, multi-layered Deferred Referral System:
(a) Layer 1 — Direct Deep Link: If the recipient has the Vridhi User App installed, tapping the link directly invokes the app via Android App Links, passing the referral parameter into local storage.
(b) Layer 2 — Backend IP Subnet Deferred Lookup: When a recipient taps a referral link in a web browser prior to installing the APK, our Vercel backend server logs the recipient's IPv4 address and user-agent string into a temporary secure database table with a 24-hour Time-To-Live (TTL). To account for cellular network IP rotation (e.g., 4G/5G mobile tower switches between browser click and app launch), our backend performs IPv4 /24 subnet prefix matching (matching the first three octets of the IP address). Upon launching the newly installed app, the client automatically queries the deferred lookup API (/api/v1/referrals/deferred-lookup) to retrieve and prefill your referral code.
(c) Layer 3 — Automated Clipboard Fallback: When the recipient clicks the download button on the Vridhi landing page, the referral code or full URL string is automatically written to the device clipboard using modern Clipboard API and fallback textarea copy commands. Upon opening the register screen, the app inspects the clipboard and extracts valid referral codes matching the pattern [A-Za-z0-9_-]{4,20}.

3.3 MULTI-LEVEL DOWNLINE HIERARCHY AND REWARD STRUCTURE
The Vridhi Network calculates referral bonuses and promotional rewards based on a multi-tiered downline hierarchy:
(a) Tier 1 (Direct Referrals): Individuals who register directly using your unique referral code.
(b) Tier 2 (Indirect Level 1): Individuals who register using the referral code of your Tier 1 direct referrals.
(c) Tier 3 (Indirect Level 2): Individuals who register using the referral code of your Tier 2 indirect referrals.
Referral points and commission percentages accrued at each level are governed by system settings set by the Administrator and are subject to periodic adjustment based on platform performance and regulatory compliance.

3.4 ANTI-FRAUD MONITORING, GAMING PROHIBITION & CLAWBACK
(a) Strictly Prohibited Practices: You shall not engage in self-referral schemes, incentivized click farms, automated bot registrations, pay-per-click advertising targeting Vridhi brand keywords, unsolicited bulk emailing (spam), deceptive marketing, or placing referral links on adult, illegal, or offensive websites.
(b) Automated Telemetry & Audit: Our security systems continuously analyze registration velocity, device fingerprints, IP subnet clusters, and payment patterns.
(c) Commission Clawback & Penalty: If any referral is determined to be fraudulent, invalid, duplicate, or subject to a refund or chargeback, Vridhi Network reserves the absolute right to reverse (clawback) all referral points and commissions credited to the referrer's account. Severe or repeated violations will result in immediate account termination, blacklisting of PAN/Aadhaar details, and legal reporting.
''',
    ),
    _TermSection(
      title: '4. DIGITAL CONTENT ACCESS, WATCH PROGRESS & SNAPSHOT REGIME',
      content: '''
4.1 DIGITAL CONTENT LICENSING
Upon successful account activation and payment, Vridhi Network grants you a limited, non-exclusive, non-transferable, non-sublicensable, revocable license to stream and view the educational video content contained within your assigned Content Snapshot strictly for your personal, non-commercial educational use. Nothing in this Agreement shall be construed as conferring any transfer of ownership, title, or intellectual property rights in any video content, documentation, graphics, audio, or underlying software code.

4.2 CONTENT DELIVERY INFRASTRUCTURE
Video content is hosted on high-performance Cloudflare R2 Object Storage buckets and Cloudinary Content Delivery Networks (CDN) utilizing adaptive streaming protocols. You are solely responsible for obtaining and maintaining all mobile devices, data plans, high-speed internet connections, and hardware required to access and stream video content. Vridhi Network shall not be held liable for streaming interruptions, buffering, latency, or data charges incurred due to poor network coverage or carrier limitations.

4.3 AUTOMATED WATCH PROGRESS TELEMETRY
The Application embeds real-time background telemetry that monitors your video playback session.
(a) Heartbeat Verification: While playing a video, the video player sends periodic encrypted heartbeats to the backend server (/api/v1/videos/:id/heartbeat) recording your exact watched timestamp and unique seconds elapsed.
(b) Accurate Duration Tracking: Seeking, skipping, fast-forwarding, or manipulating local application state does not artificially advance backend watch progress. Only verified, contiguous playback seconds confirmed by backend heartbeats are added to your total watched duration.
(c) Aggregate Snapshot Progress: Your overall percentage watched progress is calculated as:
Percentage Watched = (Total Verified Watched Seconds across Snapshot / Total Duration of Snapshot Videos) * 100.

4.4 DEVELOPER TEST MODE EXEMPTION
Accounts designated by Administrators as "Developer Test Users" or operating under administrative bypass parameters are granted unrestricted access to view all uploaded videos across all language categories. Snapshot restrictions, language change approvals, and 25% watch progress limits are bypassed for testing and demonstration purposes. Developer Test User status is strictly assigned at administrative discretion and may be revoked at any time without notice.
''',
    ),
    _TermSection(
      title: '5. EXHAUSTIVE 25% WATCH PROGRESS & 30-DAY REFUND POLICY',
      content: '''
5.1 OVERVIEW OF REFUND GUARANTEE
Vridhi Network provides a conditional money-back guarantee designed to allow users to evaluate the quality of our educational content. However, to prevent abuse of proprietary digital assets, intellectual property theft, and fraudulent content consumption, all refund requests are strictly governed by the dual criteria set forth in Sections 5.2 and 5.3 below.

5.2 THE 25% WATCH DURATION THRESHOLD RULE (CRITICAL MANDATE)
(a) Calculation of the 25% Cutoff Threshold: The maximum allowable watch limit for refund eligibility is strictly defined as exactly twenty-five percent (25.0%) of the total aggregate video duration of your assigned Content Snapshot.
For example: If your assigned language Content Snapshot contains three (3) videos with a combined total duration of 20 minutes (1,200 seconds), your strict 25% watch duration limit is exactly 5 minutes (300 seconds).
(b) IMMEDIATE AND PERMANENT VOIDING OF REFUND ELIGIBILITY: The moment your total verified watch progress reaches or exceeds 25.0% of your snapshot duration (e.g., 5 minutes and 1 second in the scenario above), your refund eligibility is IMMEDIATELY, AUTOMATICALLY, AND PERMANENTLY VOIDED.
(c) Irreversibility of Watch Log Records: Backend playback telemetry heartbeats serve as the absolute, conclusive proof of watched duration. Once backend logs record watched progress >= 25.0%, no administrative override, customer support request, or appeal can restore refund eligibility under any circumstances.

5.3 THE 30-CALENDAR-DAY EXPIRATION RULE
(a) Time Frame Mandate: All refund requests must be formally submitted through the Application's Refund Request module (/refund-request) within exactly thirty (30) calendar days initiating from the precise date and time of your successful registration payment.
(b) Automatic Expiration: Upon the conclusion of the 30th calendar day (720 consecutive hours from account payment), your refund eligibility automatically expires and terminates permanently, regardless of whether you have watched 0% or any percentage of the content.

5.4 CONDITIONS CAUSING PERMANENT REFUND DISQUALIFICATION
Without limiting the generality of the foregoing, you shall be permanently disqualified from receiving any refund under any of the following explicit conditions:
1. Reaching or exceeding 25.0% cumulative watch progress on your assigned Content Snapshot.
2. The passage of more than 30 calendar days (720 hours) from the payment timestamp.
3. Changing your preferred language assignment and consuming content in a second snapshot.
4. Engaging in account sharing, credential selling, or unauthorized access distribution.
5. Initiating an unauthorized chargeback, payment reversal, or credit card dispute with your bank or payment provider without first completing the formal internal refund request procedure.
6. Violation of any provision of Section 7 (Intellectual Property Protection) or Section 8 (Acceptable Use Policy).

5.5 REFUND REQUEST AND VERIFICATION PROCEDURE
(a) Submission: To request a refund, eligible users must navigate to Account Settings -> Refund Request (/refund-request) within the App and submit a formal claim stating the reason for refund.
(b) Automated Audit: Upon submission, our system performs an automated audit checking: (i) current calendar days elapsed since payment, (ii) total verified watch duration in backend database logs, (iii) active account status, and (iv) previous refund history.
(c) Deductions & Fees: Approved refunds shall be subject to deduction of applicable payment gateway processing fees (e.g., 2% to 3% charged by Razorpay/banks), mandatory GST/statutory taxes, and applicable administrative handling charges.
(d) Disbursement Timeline: Approved net refund amounts will be remitted to the original payment source (credit card, debit card, UPI ID, or bank account used during registration) within seven (7) to fourteen (14) business days from approval.
''',
    ),
    _TermSection(
      title: '6. PAYMENT TRANSACTIONS, SUBSCRIPTIONS & FEES',
      content: '''
6.1 PAYMENT GATEWAY INTEGRATION
All monetary transactions, registration fees, subscription charges, and package purchases on the Platform are processed securely through PCI-DSS compliant third-party payment gateways, including Razorpay. By initiating a payment transaction, you agree to comply with the terms of service, privacy policies, and transaction conditions imposed by such third-party payment processors.

6.2 PRICING, CURRENCY AND TAXES
All prices displayed on the Platform are quoted in Indian Rupees (INR, ₹) unless explicitly stated otherwise. Prices are inclusive of applicable Goods and Services Tax (GST) and statutory levies under Indian law. Vridhi Network reserves the right to modify package prices, subscription fees, or reward structures at any time. Price adjustments shall not affect active subscriptions previously paid for.

6.3 PAYMENT FAILS AND INCOMPLETE TRANSACTIONS
Vridhi Network shall not be responsible for transaction failures, bank declines, network dropouts, or delays occurring on the side of your issuing bank or payment gateway. In the event of a failed transaction where funds were debited from your account, the amount will typically be auto-refunded by your bank or payment gateway within 5 to 7 working days as per standard Banking Ombudsman regulations.

6.4 CHARGEBACK & PAYMENT DISPUTE WAIVER
You explicitly agree that you shall not file a chargeback, payment reversal, or transaction dispute with your issuing bank, credit card provider, or payment gateway without first attempting to resolve the matter directly through Vridhi Customer Support. Filing an unauthorized chargeback while having consumed >25% content or post-30 days constitutes a fraudulent transaction, subjecting your account to immediate permanent termination, civil recovery proceedings, and legal prosecution.
''',
    ),
    _TermSection(
      title: '7. INTELLECTUAL PROPERTY & CONTENT PROTECTION',
      content: '''
7.1 PROPRIETARY OWNERSHIP RIGHTS
All material available on the Platform—including but not limited to educational video lectures, curriculum blueprints, graphics, user interfaces, branding, software source code, database architecture, domain names, trademarks, logos, and audio recordings—is the exclusive intellectual property of Vridhi Network and Equity Plus, protected under the Indian Copyright Act, 1957, the Trademarks Act, 1999, and international copyright treaties.

7.2 STRICT PROHIBITION OF SCREEN RECORDING & CAPTURE
You are strictly prohibited from performing any of the following actions:
(a) Recording, screen-capturing, downloading, ripping, extracting, or saving any video content displayed on the Application using hardware recorders, software tools, ADB utilities, or third-party screen capture apps.
(b) Decompiling, disassembling, reverse engineering, decrypting, or analyzing the binary code of the Vridhi User App or Admin App.
(c) Selling, reselling, renting, leasing, broadcasting, publicly displaying, or redistributing video content or login credentials to any third party.
(d) Bypassing, disabling, or tampering with digital rights management (DRM), watermarking, Cloudflare R2 signed URL protection, or security headers.

7.3 DIGITAL WATERMARKING AND DRM TELEMETRY
The Application embeds dynamic, user-specific digital watermarks (displaying your registered user ID, email address, and IP address) overlaying video playback. Any leaked, recorded, or illegally shared video file found online will be traced via digital watermarking directly to your account, resulting in immediate criminal prosecution under Sections 65, 66, and 66B of the Information Technology Act, 2000, alongside civil damages exceeding ₹10,00,000 (Ten Lakh Indian Rupees).
''',
    ),
    _TermSection(
      title: '8. USER CONDUCT, ANTI-FRAUD POLICY & PENALTIES',
      content: '''
8.1 ACCEPTABLE USE CODE OF CONDUCT
You agree to use the Vridhi Network strictly for lawful purposes and in absolute accordance with these Terms. You agree that you shall not:
(a) Impersonate any person or entity, or falsely state or misrepresent your affiliation with Vridhi Network or any administrator.
(b) Upload, post, transmit, or share any content that is defamatory, obscene, pornographic, hateful, incites violence, or violates national security.
(c) Attempt to gain unauthorized access to our servers, database systems, administrative dashboards, or other user accounts.
(d) Deploy automated scripts, web crawlers, bots, scrapers, or stress-testing utilities against our API endpoints.

8.2 INVESTIGATIVE POWERS AND PENALTIES
Vridhi Network maintains 24/7 security auditing tools. If our system detects suspicious activities—including rapid IP shifting, referral fraud, automated playback loops, or concurrent logins—Vridhi Network reserves the immediate right to:
1. Temporarily freeze or permanently terminate your account without notice.
2. Forfeit and cancel all accumulated referral points, downline rewards, and wallet balances.
3. Block your device IMEI, IP subnet, PAN card, and Aadhaar card from future platform registration.
4. Initiate civil suits for damages and file formal First Information Reports (FIR) with Cyber Crime law enforcement agencies.
''',
    ),
    _TermSection(
      title: '9. PRIVACY, DATA PROTECTION & ANALYTICS',
      content: '''
9.1 DATA COLLECTION AND PROCESSING
Our collection, storage, and processing of your personal information are governed by our comprehensive Privacy Policy and compliant with the Digital Personal Data Protection Act, 2023 (DPDP Act). We collect personal information (Name, Email, Phone, PAN, Aadhaar) and technical telemetry (IP address, device model, OS version, video watched seconds, timestamp logs) necessary to deliver core platform functionalities, verify identity, and prevent fraud.

9.2 DATA SECURITY STANDARDS
We implement robust administrative, technical, and physical safeguards—including SSL/TLS 256-bit encryption in transit, AES-256 encryption at rest, TiDB Cloud secure database hosting, and strict role-based access control (RBAC)—to protect your sensitive personal data from unauthorized access, loss, alteration, or disclosure.

9.3 THIRD-PARTY SERVICE PROVIDERS
We utilize reputable third-party cloud infrastructure and SDK providers, including Vercel (Web Hosting), Cloudflare R2 (Video & Storage), Cloudinary (Media CDN), TiDB Cloud (Database), and Razorpay (Payment Processing). These providers process data strictly on our behalf under confidential service level agreements.
''',
    ),
    _TermSection(
      title: '10. DISCLAIMERS, LIMITATION OF LIABILITY & INDEMNIFICATION',
      content: '''
10.1 NO GUARANTEE OF FINANCIAL RETURNS
Vridhi Network is an educational content and promotional referral platform. We do NOT guarantee financial gain, employment, investment returns, or guaranteed income to any user. Referral rewards are strictly performance-based incentives tied to verified, legitimate network growth and content usage.

10.2 "AS-IS" AND "AS-AVAILABLE" WARRANTY DISCLAIMER
THE PLATFORM, INCLUDING ALL VIDEO CONTENT, SOFTWARE, FUNCTIONS, AND MATERIALS, IS PROVIDED ON AN "AS-IS" AND "AS-AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. VRIDHI NETWORK DOES NOT WARRANT THAT THE APP WILL OPERATE UNINTERRUPTED, ERROR-FREE, OR FREE OF VIRUSES OR MALICIOUS COMPONENTS.

10.3 LIMITATION OF MONETARY LIABILITY
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL VRIDHI NETWORK, EQUITY PLUS, ITS DIRECTORS, OFFICERS, EMPLOYEES, AGENTS, OR AFFILIATES BE LIABLE FOR ANY INDIRECT, INCIDENTAL, CONSEQUENTIAL, SPECIAL, PUNITIVE, OR EXEMPLARY DAMAGES (INCLUDING LOSS OF PROFITS, DATA, GOODWILL, OR BUSINESS INTERRUPTION) ARISING OUT OF OR IN CONNECTION WITH YOUR USE OR INABILITY TO USE THE PLATFORM. OUR AGGREGATE LIABILITY FOR ALL CLAIMS SHALL NOT EXCEED THE TOTAL MONETARY AMOUNT PAID BY YOU TO VRIDHI NETWORK IN THE THIRTY (30) DAYS IMMEDIATELY PRECEDING THE CLAIM.

10.4 USER INDEMNIFICATION OBLIGATION
You agree to defend, indemnify, and hold harmless Vridhi Network, Equity Plus, its officers, directors, employees, and agents from and against all claims, liabilities, damages, losses, costs, expenses, or fees (including reasonable attorneys' fees) arising from: (a) your violation of these Terms; (b) your infringement of third-party intellectual property rights; (c) your fraudulent account activities; or (d) your misuse of video content.
''',
    ),
    _TermSection(
      title: '11. DISPUTE RESOLUTION, GOVERNING LAW & JURISDICTION',
      content: '''
11.1 MANDATORY INFORMAL RESOLUTION
Prior to instituting any formal legal proceeding, you agree to attempt to resolve any dispute, controversy, or claim arising out of or relating to these Terms by contacting Vridhi Customer Support in writing at support@vridhinetwork.com. Both parties agree to negotiate in good faith for a minimum period of thirty (30) business days.

11.2 BINDING ARBITRATION
If a dispute cannot be resolved through informal negotiations within thirty (30) business days, it shall be finally settled by binding arbitration in accordance with the Arbitration and Conciliation Act, 1996 (as amended). The arbitration tribunal shall consist of a sole arbitrator appointed by Vridhi Network. The language of arbitration shall be English, and the venue shall be Kolkata, West Bengal, India. The arbitral award shall be final and binding on both parties.

11.3 GOVERNING LAW AND EXCLUSIVE JURISDICTION
This Agreement shall be governed by, interpreted, and construed strictly in accordance with the laws of the Republic of India, without giving effect to conflict of law principles. Subject to Section 11.2, you explicitly submit to the exclusive jurisdiction of the competent civil courts located in Kolkata, West Bengal, India.
''',
    ),
    _TermSection(
      title: '12. MISCELLANEOUS PROVISIONS & OFFICIAL CONTACT DETAILS',
      content: '''
12.1 SEVERABILITY
If any provision of these Terms is found to be unlawful, void, or for any reason unenforceable by a court of competent jurisdiction, that provision shall be deemed severable from this Agreement and shall not affect the validity and enforceability of any remaining provisions.

12.2 ENTIRE AGREEMENT
These Terms, alongside the Privacy Policy, Refund Policy, and Disclaimer Policy, constitute the entire legal agreement between you and Vridhi Network concerning your use of the Platform, superseding all prior oral or written communications, understandings, or proposals.

12.3 OFFICIAL SUPPORT AND GRIEVANCE OFFICER DETAILS
For any questions, legal notices, refund inquiries, or compliance grievances regarding these Terms & Conditions, please contact our designated Grievance Officer:

Vridhi Network Support & Compliance Cell
Email: support@vridhinetwork.com / equityplus42@gmail.com
Web Help Desk: https://vridhi-network-app.vercel.app/support
Official Platform Domain: https://vridhi-network-app.vercel.app
Corporate Office: Vridhi Network Hub, Salt Lake Sector V, Kolkata, West Bengal, India — 700091.

Document Version: 2.1.0 (Production Master Legal Terms)
Last Legal Audit & Publication Date: September 5, 2026.
''',
    ),
  ];

  List<_TermSection> get _filteredSections {
    if (_searchQuery.trim().isEmpty) return _sections;
    final q = _searchQuery.toLowerCase();
    return _sections.where((s) {
      return s.title.toLowerCase().contains(q) || s.content.toLowerCase().contains(q);
    }).toList();
  }

  int get _totalWordCount {
    int count = 0;
    for (var s in _sections) {
      count += s.title.split(RegExp(r'\s+')).length;
      count += s.content.split(RegExp(r'\s+')).length;
    }
    return count;
  }

  void _scrollToSection(int index) {
    setState(() {
      _selectedSectionIndex = index;
    });
    // Scroll animation estimation
    final targetOffset = index * 420.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSections;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Terms & Conditions'),
            Text(
              'Comprehensive Legal Agreement (${_totalWordCount}+ Words)',
              style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.neonCyan),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vertical_align_top, color: AppTheme.neonCyan),
            tooltip: 'Scroll to Top',
            onPressed: () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: Column(
          children: [
            // Search Bar & Filter Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg.withOpacity(0.6),
                border: const Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.outfit(color: AppTheme.lightText),
                    decoration: InputDecoration(
                      hintText: 'Search terms (e.g. 25%, Refund, KYC, Referral)...',
                      hintStyle: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.neonCyan, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppTheme.softGrey, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick Jump Section Chips
                  SizedBox(
                    height: 32,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sections.length,
                      itemBuilder: (context, idx) {
                        final secNum = idx + 1;
                        final isSelected = _selectedSectionIndex == idx;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('Sec $secNum', style: GoogleFonts.outfit(fontSize: 11, color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: isSelected ? AppTheme.neonCyan : AppTheme.cardBg,
                            side: BorderSide(color: isSelected ? AppTheme.neonCyan : Colors.white24),
                            onPressed: () => _scrollToSection(idx),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Main Document List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: AppTheme.softGrey),
                            const SizedBox(height: 12),
                            Text(
                              'No matching terms found',
                              style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.lightText, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching for keywords like "refund", "25%", "KYC", or "referral".',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final sec = filtered[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Title Banner
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPurple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.4)),
                                ),
                                child: Text(
                                  sec.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neonCyan,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SelectableText(
                                sec.content,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: AppTheme.lightText,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermSection {
  final String title;
  final String content;

  _TermSection({required this.title, required this.content});
}
