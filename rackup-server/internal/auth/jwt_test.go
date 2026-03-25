package auth

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var testSecret = []byte("test-secret-key-that-is-at-least-32-bytes-long!!")

func TestIssueAndValidateRoundTrip(t *testing.T) {
	tokenStr, err := IssueToken(testSecret, "ABCD", "hash123", "Alice")
	if err != nil {
		t.Fatalf("IssueToken failed: %v", err)
	}

	claims, err := ValidateClaims(testSecret, tokenStr)
	if err != nil {
		t.Fatalf("ValidateClaims failed: %v", err)
	}

	if claims.RoomCode != "ABCD" {
		t.Errorf("expected RoomCode ABCD, got %q", claims.RoomCode)
	}
	if claims.DeviceIDHash != "hash123" {
		t.Errorf("expected DeviceIDHash hash123, got %q", claims.DeviceIDHash)
	}
	if claims.DisplayName != "Alice" {
		t.Errorf("expected DisplayName Alice, got %q", claims.DisplayName)
	}
}

func TestIssueToken_EmptyDisplayName(t *testing.T) {
	tokenStr, err := IssueToken(testSecret, "WXYZ", "hash456", "")
	if err != nil {
		t.Fatalf("IssueToken failed: %v", err)
	}

	claims, err := ValidateClaims(testSecret, tokenStr)
	if err != nil {
		t.Fatalf("ValidateClaims failed: %v", err)
	}

	if claims.DisplayName != "" {
		t.Errorf("expected empty DisplayName, got %q", claims.DisplayName)
	}
}

func TestValidateClaims_ExpiredToken(t *testing.T) {
	now := time.Now().Add(-25 * time.Hour)
	claims := Claims{
		RoomCode:     "ABCD",
		DeviceIDHash: "hash123",
		DisplayName:  "Alice",
		RegisteredClaims: jwt.RegisteredClaims{
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(TokenExpiry)),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenStr, err := token.SignedString(testSecret)
	if err != nil {
		t.Fatalf("failed to sign token: %v", err)
	}

	_, err = ValidateClaims(testSecret, tokenStr)
	if err == nil {
		t.Fatal("expected error for expired token, got nil")
	}
}

func TestValidateClaims_InvalidSignature(t *testing.T) {
	tokenStr, err := IssueToken(testSecret, "ABCD", "hash123", "Alice")
	if err != nil {
		t.Fatalf("IssueToken failed: %v", err)
	}

	wrongSecret := []byte("wrong-secret-key-that-is-at-least-32-bytes-long!")
	_, err = ValidateClaims(wrongSecret, tokenStr)
	if err == nil {
		t.Fatal("expected error for invalid signature, got nil")
	}
}

func TestValidateClaims_MalformedToken(t *testing.T) {
	_, err := ValidateClaims(testSecret, "not-a-valid-jwt")
	if err == nil {
		t.Fatal("expected error for malformed token, got nil")
	}
}

func TestIssueToken_SecretTooShort(t *testing.T) {
	_, err := IssueToken([]byte("short"), "ABCD", "hash123", "Alice")
	if err == nil {
		t.Fatal("expected error for short secret, got nil")
	}
}

func TestValidateClaims_SecretTooShort(t *testing.T) {
	_, err := ValidateClaims([]byte("short"), "some-token")
	if err == nil {
		t.Fatal("expected error for short secret, got nil")
	}
}

func TestClaimsExtraction(t *testing.T) {
	tokenStr, err := IssueToken(testSecret, "XYZW", "devicehash", "Bob")
	if err != nil {
		t.Fatalf("IssueToken failed: %v", err)
	}

	claims, err := ValidateClaims(testSecret, tokenStr)
	if err != nil {
		t.Fatalf("ValidateClaims failed: %v", err)
	}

	if claims.ExpiresAt == nil {
		t.Fatal("expected ExpiresAt to be set")
	}
	if claims.IssuedAt == nil {
		t.Fatal("expected IssuedAt to be set")
	}

	expectedExpiry := claims.IssuedAt.Time.Add(TokenExpiry)
	if !claims.ExpiresAt.Time.Equal(expectedExpiry) {
		t.Errorf("expected expiry %v, got %v", expectedExpiry, claims.ExpiresAt.Time)
	}
}
