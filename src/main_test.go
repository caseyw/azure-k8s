package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestHealthCheckHandler(t *testing.T) {
	// Create a request to pass to our handler. We don't have any query parameters for now, so we'll
	// pass 'nil' as the third parameter.
	req, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Fatal(err)
	}

	// We create a ResponseRecorder (which satisfies http.ResponseWriter) to record the response.
	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(demo)

	// Our handlers satisfy http.Handler, so we can call their ServeHTTP method
	// directly and pass in our Request and ResponseRecorder.
	handler.ServeHTTP(rr, req)

	// Check the status code is what we expect.
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Returned the wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	var payloadResponse Payload
	json.Unmarshal([]byte(rr.Body.String()), &payloadResponse)

	// Check the response body is what we expect.
	expected := "Automate all the things!"
	if payloadResponse.Message != expected {
		t.Errorf("Didn't see our automation message: got %v want %v",
			payloadResponse.Message, expected)
	}

	// Check we have something looking like a timestamp
	// Note: If tests are slow, this could cause a problem.
	// We would need to account for a little drift.
	now := time.Now().Unix()
	if payloadResponse.Timestamp != now {
		t.Errorf("Timestamp doesn't match: got %v want: %v",
			payloadResponse.Timestamp, now)
	}
}
