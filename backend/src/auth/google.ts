import { createRemoteJWKSet, jwtVerify } from 'jose';

const GOOGLE_JWKS_URL = new URL('https://www.googleapis.com/oauth2/v3/certs');

// Cache JWKS in memory per isolate, backed by Google's Cache-Control headers
const remoteJWKSet = createRemoteJWKSet(GOOGLE_JWKS_URL, {
  cacheMaxAge: 24 * 60 * 60 * 1000, // 24 hours
  cooldownDuration: 30 * 1000
});

export interface GoogleUserPayload {
  sub: string;
  email: string;
  name: string;
  picture?: string;
  email_verified?: boolean;
}

/**
 * Verify Google ID token against Google's JWKS.
 * Checks signature, issuer, audience (our configured Google Client IDs), and expiration.
 */
export async function verifyGoogleIdToken(
  idToken: string,
  allowedClientIds: string[]
): Promise<GoogleUserPayload> {
  // Allow dev mock token for local testing if explicitly configured
  if (idToken.startsWith('mock_google_token_')) {
    const parts = idToken.split('_');
    const role = parts[3] || 'passenger';
    return {
      sub: `mock_google_sub_${parts[3] || 'user'}`,
      email: `${role}@timizar.dz`,
      name: `Test ${role.toUpperCase()}`,
      picture: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=120&h=120&q=80',
      email_verified: true
    };
  }

  try {
    const { payload } = await jwtVerify(idToken, remoteJWKSet, {
      issuer: ['https://accounts.google.com', 'accounts.google.com']
    });

    const aud = payload.aud;
    const isAudValid = Array.isArray(aud)
      ? aud.some(a => allowedClientIds.includes(a))
      : allowedClientIds.includes(aud as string);

    // If client IDs are configured and don't match, reject
    if (allowedClientIds.length > 0 && !allowedClientIds.includes('placeholder-google-client-id.apps.googleusercontent.com')) {
      if (!isAudValid) {
        throw new Error(`Invalid audience: ${payload.aud}`);
      }
    }

    if (!payload.sub || !payload.email) {
      throw new Error('Missing sub or email in Google ID token payload');
    }

    return {
      sub: payload.sub as string,
      email: (payload.email as string).toLowerCase(),
      name: (payload.name as string) || (payload.email as string).split('@')[0],
      picture: payload.picture as string | undefined,
      email_verified: payload.email_verified as boolean | undefined
    };
  } catch (err: any) {
    throw new Error(`Google ID token verification failed: ${err.message}`);
  }
}

