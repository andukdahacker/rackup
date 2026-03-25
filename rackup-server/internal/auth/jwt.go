package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// MinSecretLength is the minimum required length for the JWT signing secret.
const MinSecretLength = 32

// TokenExpiry is the lifetime of an issued JWT (24 hours for ephemeral rooms).
const TokenExpiry = 24 * time.Hour

// Claims holds the custom JWT claims for a RackUp session.
type Claims struct {
	RoomCode    string `json:"roomCode"`
	DeviceIDHash string `json:"deviceIdHash"`
	DisplayName string `json:"displayName"`
	jwt.RegisteredClaims
}

// IssueToken creates a signed HS256 JWT with room, device, and display name claims.
func IssueToken(secret []byte, roomCode, deviceIDHash, displayName string) (string, error) {
	if len(secret) < MinSecretLength {
		return "", fmt.Errorf("jwt secret must be at least %d bytes", MinSecretLength)
	}

	now := time.Now()
	claims := Claims{
		RoomCode:     roomCode,
		DeviceIDHash: deviceIDHash,
		DisplayName:  displayName,
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(TokenExpiry)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secret)
}

// ValidateClaims parses and validates a JWT string, returning the claims if valid.
func ValidateClaims(secret []byte, tokenString string) (*Claims, error) {
	if len(secret) < MinSecretLength {
		return nil, fmt.Errorf("jwt secret must be at least %d bytes", MinSecretLength)
	}

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return secret, nil
	})
	if err != nil {
		return nil, fmt.Errorf("invalid token: %w", err)
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}

	return claims, nil
}
