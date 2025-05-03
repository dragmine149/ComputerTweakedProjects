import time
import os
import shutil
import json
import argparse
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class FileHandler(FileSystemEventHandler):
    def __init__(self, source_directory, target_directory):
        self.source_directory = source_directory
        self.target_directory = target_directory

    def on_modified(self, event):
        if not event.is_directory:
            try:
                source_path = event.src_path

                # Get the path difference between source directory and current file
                rel_path = os.path.relpath(source_path, self.source_directory)
                print(rel_path)
                # rel_path = os.path.basename(source_path)
                target_path = os.path.join(self.target_directory, rel_path)
                print(target_path)

                # Create target subdirectories if they don't exist
                os.makedirs(os.path.dirname(target_path), exist_ok=True)

                # Copy the file to target directory
                shutil.copy2(source_path, target_path)
                print(f"File copied: {rel_path} -> {target_path}")
            except Exception as e:
                print(f"Error copying file: {str(e)}")

def start_monitoring(source_directory, target_directory):
    # Create target directory if it doesn't exist
    if not os.path.exists(target_directory):
        os.makedirs(target_directory)
        print(f"Created target directory: {target_directory}")

    # Initialize event handler and observer
    event_handler = FileHandler(source_directory, target_directory)
    observer = Observer()
    observer.schedule(event_handler, source_directory, recursive=True)

    print(f"Starting to monitor directory: {source_directory}")
    print(f"Files will be copied to: {target_directory}")

    # Start the observer
    observer.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        print("\nMonitoring stopped")

    observer.join()

def save_config(source_dir, target_dir):
    config = {
        'source_directory': source_dir,
        'target_directory': target_dir
    }
    with open('.copier_config', 'w') as f:
        json.dump(config, f)

def load_config():
    try:
        with open('.copier_config', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return None

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Monitor a directory and copy modified files to a target directory')
    parser.add_argument('source_dir', nargs='?', help='Source directory to monitor')
    parser.add_argument('target_dir', nargs='?', help='Target directory to copy files to')
    args = parser.parse_args()

    if args.source_dir and args.target_dir:
        # Use command line arguments
        source_dir = os.path.abspath(os.path.expanduser(args.source_dir))
        target_dir = os.path.abspath(os.path.expanduser(args.target_dir))
        # Save the configuration
        save_config(source_dir, target_dir)
    else:
        # Try to load saved configuration
        config = load_config()
        if config:
            source_dir = config['source_directory']
            target_dir = config['target_directory']
        else:
            print("Error: Please provide source and target directories")
            parser.print_help()
            exit(1)

    # Start monitoring
    start_monitoring(source_dir, target_dir)
