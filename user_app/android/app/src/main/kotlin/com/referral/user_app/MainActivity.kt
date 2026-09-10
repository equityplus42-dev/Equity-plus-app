package com.referral.user_app

import android.os.Build
import androidx.credentials.CreatePublicKeyCredentialRequest
import androidx.credentials.CreatePublicKeyCredentialResponse
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetPublicKeyCredentialOption
import androidx.credentials.PublicKeyCredential
import androidx.credentials.exceptions.CreateCredentialCancellationException
import androidx.credentials.exceptions.CreateCredentialException
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.referral.user_app/passkey"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPasskeySupported" -> {
                    // Passkeys via CredentialManager require Android 9 (API 28) or higher
                    val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P
                    result.success(supported)
                }
                "createPasskey" -> {
                    val requestJson = call.argument<String>("requestJson")
                    if (requestJson == null) {
                        result.error("INVALID_ARGUMENT", "requestJson cannot be null", null)
                        return@setMethodCallHandler
                    }
                    createPasskey(requestJson, result)
                }
                "getPasskey" -> {
                    val requestJson = call.argument<String>("requestJson")
                    if (requestJson == null) {
                        result.error("INVALID_ARGUMENT", "requestJson cannot be null", null)
                        return@setMethodCallHandler
                    }
                    getPasskey(requestJson, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createPasskey(requestJson: String, result: MethodChannel.Result) {
        val credentialManager = CredentialManager.create(this)
        val createPublicKeyCredentialRequest = CreatePublicKeyCredentialRequest(requestJson)

        lifecycleScope.launch {
            try {
                val response = credentialManager.createCredential(
                    context = this@MainActivity,
                    request = createPublicKeyCredentialRequest
                ) as CreatePublicKeyCredentialResponse

                result.success(response.registrationResponseJson)
            } catch (e: CreateCredentialCancellationException) {
                result.error("USER_CANCELLED", "Passkey creation cancelled by user", null)
            } catch (e: CreateCredentialException) {
                result.error("CREATE_FAILED", e.message ?: "Passkey creation failed", null)
            } catch (e: Exception) {
                result.error("UNEXPECTED_ERROR", e.message ?: "Unexpected error", null)
            }
        }
    }

    private fun getPasskey(requestJson: String, result: MethodChannel.Result) {
        val credentialManager = CredentialManager.create(this)
        val getPublicKeyCredentialOption = GetPublicKeyCredentialOption(requestJson)
        val getCredentialRequest = GetCredentialRequest.Builder()
            .addCredentialOption(getPublicKeyCredentialOption)
            .build()

        lifecycleScope.launch {
            try {
                val response = credentialManager.getCredential(
                    context = this@MainActivity,
                    request = getCredentialRequest
                )

                val credential = response.credential
                if (credential is PublicKeyCredential) {
                    result.success(credential.authenticationResponseJson)
                } else {
                    result.error("UNEXPECTED_CREDENTIAL_TYPE", "Expected PublicKeyCredential", null)
                }
            } catch (e: GetCredentialCancellationException) {
                result.error("USER_CANCELLED", "Passkey authentication cancelled by user", null)
            } catch (e: GetCredentialException) {
                result.error("AUTH_FAILED", e.message ?: "Passkey authentication failed", null)
            } catch (e: Exception) {
                result.error("UNEXPECTED_ERROR", e.message ?: "Unexpected error", null)
            }
        }
    }
}
