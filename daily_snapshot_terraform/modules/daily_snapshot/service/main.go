package main

import (
	"encoding/xml"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
	"github.com/slack-go/slack"
	"encoding/json"
)

const (
	base_url = "https://forest-snapshots.fra1.digitaloceanspaces.com"
	CHANNEL_NAME = "#forest-dump"
)

type S3 struct {
	XMLName xml.Name `xml:"ListBucketResult"`
	Snapshots []Snapshot `xml:"Contents"`
}

type Snapshot struct {
	Key string `xml:"Key"`
	Size int `xml:"Size"`
}


// Downloads and generate correscorresponding for the filops snapshot
func fetchFilopsSnapshot(chain string) error {
	cmd := exec.Command("/bin/sh", "./download_snapshot.sh")
	cmd.Env = append(os.Environ(), fmt.Sprintf("CHAIN=%s", chain))

	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("Oops, something went wrong.", err)
	}

	return nil
}

// renames the download the snapshot and shasum to follow the naming convention
func namingConvention(dir, folder string) error {
	files, err := ioutil.ReadDir(dir)
	if err != nil {
		return err
	}

	re := regexp.MustCompile(`(\d+)_(\d{4})_(\d{2})_(\d{2})T(\d{2})_(\d{2})_(\d{2})Z\.car\.zst`)
	for _, file := range files {
		filename := file.Name()
		if !strings.HasSuffix(filename, ".car.zst") {
			continue
		}
		match := re.FindStringSubmatch(filename)

		if len(match) < 8 {
			fmt.Printf("Filename '%v' doesn't match the expected format\n", filename)
			continue
		}

		height, year, month, day := match[1], match[2], match[3], match[4]
		newFilename := fmt.Sprintf("forest_snapshot_%v_%v-%v-%v_height_%v.car.zst", folder, year, month, day, height)

		err = os.Rename(filepath.Join(dir, filename), filepath.Join(dir, newFilename))
		if err != nil {
			fmt.Printf("Error renaming '%v': %v\n", filename, err)
		}
	}

	return nil
}

func getLatestSnapshot(folder string) (time.Time, error) {
	resp, err := http.Get(base_url)
	if err != nil {
		return time.Time{}, err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return time.Time{}, err
	}

	s3 := S3{}
	err = xml.Unmarshal(body, &s3)
	if err != nil {
		return time.Time{}, err
	}

	r := regexp.MustCompile(`([^_]+?)_snapshot_([^_]+?)_(\d{4}-\d{2}-\d{2})_height_(\d+).car(.zst)?$`)
	latestSnapshot := time.Time{}

	for _, snapshot := range s3.Snapshots {
		snapshot_name := snapshot.Key

		if strings.HasPrefix(snapshot_name, folder) && (strings.HasSuffix(snapshot_name, ".car") || strings.HasSuffix(snapshot_name, ".car.zst") || strings.HasSuffix(snapshot_name, ".sha256sum")) {
			match := r.FindStringSubmatch(snapshot_name)
			if len(match) > 0 {
				snapshot_date_str := match[3]
				t, _ := time.Parse("2006-01-02", snapshot_date_str)
				if t.After(latestSnapshot) {
					latestSnapshot = t
				}
			}
		}
	}

	if latestSnapshot.IsZero() {
		return time.Time{}, errors.New("No valid snapshots found")
	}

	return latestSnapshot, nil
}

func slackAlert(message string, thread_ts string) (string, error) {
	token := os.Getenv("SLACK_TOKEN")
	client := slack.New(token)

	// Convert the message into JSON format
	jsonMessage, err := json.MarshalIndent(message, "", "    ")
	if err != nil {
		return "", err
	}

	// Format the message as a code block for better readability
	message = fmt.Sprintf("```%s```", string(jsonMessage))

	// Send the message
	_, timestamp, err := client.PostMessage(
		CHANNEL_NAME,
		slack.MsgOptionText(message, false),
		slack.MsgOptionTS(thread_ts),
	)

	if err != nil {
		return "", fmt.Errorf("Slack API error: %w", err)
	}

	return timestamp, nil
}


func main() {
	dir := "./" // Set this to the directory where your files are

	folders := []string{"mainnet", "calibnet"}
	for _, folder := range folders {
		latestSnapshot, err := getLatestSnapshot(folder)
		if err != nil {
			fmt.Println(err.Error())
			return
		}
		oneDayAgo := time.Now().Add(-1 * time.Hour)
		if latestSnapshot.Before(oneDayAgo) {
			fmt.Printf("The latest snapshot in the %s folder is older than one day\n", folder)
			err = fetchFilopsSnapshot(folder)
			if err != nil {
				fmt.Println(err.Error())
				return
			}
			err = namingConvention(dir, folder)
			if err != nil {
				fmt.Println(err.Error())
				return
			}
		} else {
			fmt.Printf("The latest snapshot in the %s folder is not older than one day\n", folder)
		}
	}
}
