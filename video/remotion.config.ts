import {Config} from '@remotion/cli/config';

// Use the pre-installed headless shell instead of downloading one.
Config.setBrowserExecutable('/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell');
Config.setConcurrency(2);
