function print_info()
{
  GREEN='\033[0;32m'
  NC='\033[0m'
  tput bold
  echo -e "$GREEN $1${NC}"
  echo -e "$GREEN $1${NC}" >> "$LOGFILENAME"
  tput sgr0
}

function print_error()
{
  RED='\033[0;31m'
  NC='\033[0m'
  tput bold
  echo -e "$RED $1${NC}"
  echo -e "$RED $1${NC}" >> "$LOGFILENAME"
  echo "$1"
  tput sgr0
}