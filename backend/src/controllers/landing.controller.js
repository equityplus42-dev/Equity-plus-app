const prisma = require('../config/database');
const appReleaseService = require('../services/appRelease.service');
const logger = require('../utils/logger');

function extractClientIp(req) {
  const rawIp = req.headers['x-real-ip'] || 
                (req.headers['x-forwarded-for'] ? req.headers['x-forwarded-for'].split(',')[0] : null) || 
                req.socket?.remoteAddress || 
                req.ip || 
                '127.0.0.1';
  return rawIp.toString().trim().replace(/^::ffff:/, '');
}

class LandingController {
  /**
   * Public Referral Landing & APK Download Page
   * GET /download?ref=ABC123
   * GET /r/:refCode
   */
  async handleReferralLanding(req, res, next) {
    try {
      let refCode = req.query.ref || req.params.refCode || '';
      refCode = typeof refCode === 'string' ? refCode.trim().toUpperCase() : '';

      let referrerName = null;
      let isValidReferral = false;

      if (refCode) {
        const referrer = await prisma.user.findUnique({
          where: { referralCode: refCode },
          include: { profile: true },
        });

        if (referrer) {
          isValidReferral = true;
          referrerName = referrer.profile
            ? `${referrer.profile.firstName || ''} ${referrer.profile.lastName || ''}`.trim()
            : referrer.email;

          // Record client IP + user-agent for post-install deferred referral attribution
          const ipAddress = extractClientIp(req);
          const userAgent = (req.headers['user-agent'] || '').toString();

          try {
            await prisma.deferredReferral.create({
              data: {
                referralCode: refCode,
                ipAddress,
                userAgent,
                expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 Hours TTL
              },
            });
          } catch (err) {
            logger.warn(`[LandingController] Failed to store deferred referral: ${err.message}`);
          }
        }
      }

      // Fetch the LATEST active USER_APP Android release
      const releaseInfo = await appReleaseService.checkVersion({
        appType: 'USER_APP',
        platform: 'ANDROID',
      });

      const apkDownloadUrl = releaseInfo.downloadUrl || '#';
      const isDirect = req.query.direct === 'true';

      // Direct APK download option
      if (isDirect && apkDownloadUrl && apkDownloadUrl !== '#') {
        return res.redirect(302, apkDownloadUrl);
      }

      // Modern Glassmorphic Web Landing Page
      const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Vridhi Network — Join App</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;800;900&display=swap" rel="stylesheet">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Outfit', sans-serif; }
    body {
      background: #0B0E17;
      color: #F3F4F6;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      background: rgba(26, 31, 55, 0.7);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 24px;
      padding: 36px 28px;
      max-width: 440px;
      width: 100%;
      text-align: center;
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
    }
    .badge {
      display: inline-block;
      padding: 6px 16px;
      border-radius: 50px;
      font-size: 12px;
      font-weight: 800;
      letter-spacing: 1px;
      text-transform: uppercase;
      margin-bottom: 20px;
      background: rgba(0, 242, 254, 0.15);
      color: #00F2FE;
      border: 1px solid rgba(0, 242, 254, 0.3);
    }
    h1 { font-size: 28px; font-weight: 900; margin-bottom: 10px; color: #FFFFFF; }
    p { color: #9CA3AF; font-size: 14px; line-height: 1.5; margin-bottom: 24px; }
    .ref-box {
      background: rgba(107, 70, 193, 0.2);
      border: 2px dashed #6B46C1;
      border-radius: 16px;
      padding: 16px;
      margin-bottom: 28px;
    }
    .ref-label { font-size: 11px; text-transform: uppercase; color: #9CA3AF; letter-spacing: 1.5px; font-weight: 700; margin-bottom: 6px; }
    .ref-code { font-size: 26px; font-weight: 900; color: #00F2FE; letter-spacing: 3px; }
    .btn {
      display: block;
      width: 100%;
      padding: 16px;
      background: linear-gradient(135deg, #6B46C1 0%, #D53F8C 100%);
      color: #FFFFFF;
      font-size: 16px;
      font-weight: 800;
      text-decoration: none;
      border-radius: 16px;
      border: none;
      cursor: pointer;
      box-shadow: 0 10px 25px rgba(107, 70, 193, 0.4);
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .btn:hover { transform: translateY(-2px); box-shadow: 0 14px 30px rgba(107, 70, 193, 0.6); }
    .footer-note { font-size: 12px; color: #6B7280; margin-top: 20px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">VRIDHI NETWORK INVITATION</div>
    <h1>Get Started on Vridhi</h1>
    <p>${referrerName ? `<strong>${referrerName}</strong> invited you to join the Vridhi Network.` : 'Download the official Vridhi User App to complete registration.'}</p>
    
    ${isValidReferral ? `
    <div class="ref-box">
      <div class="ref-label">Your Referral Code</div>
      <div class="ref-code" id="refCode">${refCode}</div>
    </div>
    ` : ''}

    <a href="${apkDownloadUrl}" class="btn" id="downloadBtn">Download User App (APK) — Cloudflare R2 ⚡</a>
    <div class="footer-note">Latest Version ${releaseInfo.latestVersion || '1.1.2'} (Build ${releaseInfo.latestBuildNumber || 4}) • Direct Cloudflare R2 Delivery</div>
  </div>

  <script>
    function copyRef() {
      const code = "${refCode}";
      if (!code) return;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(code).catch(function() { fallbackCopy(code); });
      } else {
        fallbackCopy(code);
      }
    }
    function fallbackCopy(text) {
      try {
        const textArea = document.createElement("textarea");
        textArea.value = text;
        textArea.style.position = "fixed";
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
      } catch (err) {}
    }
    window.addEventListener('DOMContentLoaded', copyRef);
    document.getElementById('downloadBtn')?.addEventListener('click', copyRef);
  </script>
</body>
</html>
      `;

      return res.status(200).send(html);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new LandingController();
