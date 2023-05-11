#!/bin/bash

#shows a license info
ShowLicense () {
zenity --text-info --title="License" --checkbox="I read and accept the terms."
case $? in
    0)
        echo "Started application!" 
        return ;;
    1)
        echo "Stop installation!"
        exit 1 ;;
    -1)
        echo "An unexpected error has occurred."
        exit 1 ;;
esac
}

#performs necessary actions to install ImageMagick
InstallImageMagick () {
#check if ImageMagick is installed
if ! [ -x "$(command -v convert)" ]; then
     echo 'ImageMagick is not installed. Installing now...' >&2
  
     #checks if user has yum command supported on OS
     if [ -x "$(command -v yum)" ]; then
          sudo yum install ImageMagick -y
     elif [ -x "$(command -v apt-get)" ]; then
          sudo apt-get update
          sudo apt-get install ImageMagick -y
     else
          echo 'Error: Could not find a supported package manager.' >&2
          exit 1
     fi
fi
}

#displays a file selection window for a user to choose an image from
ChooseImage() {
IMAGE=$(zenity --file-selection --title="Select an image file" --file-filter="*.jpg *.jpeg *.png" --)

case $? in
    0)
        echo "\"$IMAGE\" selected."
        return ;;
    1)
        echo "Operation cancelled!"
        exit 1 ;;
    -1)
        echo "An unexpected error has occurred."
        exit 1 ;;
esac
}

IsNumber () {
local ENTERED=$1

if [[ $ENTERED =~ ^-?[0-9]+$ ]]; then
    echo 1
else
    echo 0
fi
}

#rotates the image by the angle selected by user
RotateClockwise () {
local ANGLE=$(zenity --scale --title "Select angle" --text "Select rotation angle:" \
--min-value=0 --max-value=360 --step=1 --value=0 --width=400)

if [ "$(IsNumber "$ANGLE")" -eq 1 ]; then
convert "$TMP_IMAGE_NAME" -rotate $ANGLE "$TMP_IMAGE_NAME"
((OPERATION_CNT += 1))
else
echo "Cancelled 'RotateClockwise' operation!"
fi

}

RotateCounterclockwise () {
local ANGLE=$(zenity --scale --title "Select angle" --text "Select rotation angle:" \
--min-value=0 --max-value=360 --step=1 --value=0 --width=400)

if [ "$(IsNumber "$ANGLE")" -eq 1 ]; then
convert "$TMP_IMAGE_NAME" -rotate -$ANGLE "$TMP_IMAGE_NAME"
((OPERATION_CNT += 1))
else
echo "Cancelled 'RotateCounterclockwise' operation!"
fi
}

FlipHorizontally () {
convert "$TMP_IMAGE_NAME" -flop "$TMP_IMAGE_NAME"
((OPERATION_CNT += 1))
}

FlipVertically () {
convert "$TMP_IMAGE_NAME" -flip "$TMP_IMAGE_NAME"
((OPERATION_CNT += 1))
}

#resizes image by values entered by user
ResizeImage () {
local WIDTH=$(zenity --entry --title "Resize" --text "Enter the new width:")
local HEIGHT=$(zenity --entry --title "Resize" --text "Enter the new height:")

#checking if entered values are numbers
while [[ "$(IsNumber "$WIDTH")" -eq 0 ]] || [[ "$(IsNumber "$HEIGHT")" -eq 0 ]]; do
    local WIDTH=$(zenity --entry --title "Resize" --text "Enter the new width:")
    local HEIGHT=$(zenity --entry --title "Resize" --text "Enter the new height:")
done

convert "$TMP_IMAGE_NAME" -resize "${WIDTH}x${HEIGHT}" "$TMP_IMAGE_NAME"
((OPERATION_CNT += 1))
}

CropImage () {
local X Y WIDTH HEIGHT
local USER_OUTPUT=$(zenity --forms --title "Crop" --text "Enter the coordinates and dimensions:" \
--add-entry "X coordinate of the top left corner:" \
--add-entry "Y coordinate of the top left corner:" \
--add-entry "New width:" \
--add-entry "New height:")
#echo "USER_OUTPUT: "$USER_OUTPUT
local OLD_SEPARATOR=$IFS
IFS='|'
read -r X Y WIDTH HEIGHT <<< "$USER_OUTPUT"

while [[ "$(IsNumber "$WIDTH")" -eq 0 ]] || [[ "$(IsNumber "$HEIGHT")" -eq 0 ]] \
   || [[ "$(IsNumber "$X")" -eq 0 ]] || [[ "$(IsNumber "$Y")" -eq 0 ]]; do
    zenity --info --text="Entered wrong values! Please enter again."
    
    local USER_OUTPUT=$(zenity --forms --title "Crop" --text "Enter the coordinates and dimensions:" \
    --add-entry "X coordinate of the top left corner:" \
    --add-entry "Y coordinate of the top left corner:" \
    --add-entry "New width:" \
    --add-entry "New height:")
        read -r X Y WIDTH HEIGHT <<< "$USER_OUTPUT"
done
IFS=$OLD_SEPARATOR
convert "$TMP_IMAGE_NAME" -crop "${WIDTH}x${HEIGHT}+${X}+${Y}" "$TMP_IMAGE_NAME"
((OPERATION_CNT += 1))
}

GreyscaleImage () {
convert "$TMP_IMAGE_NAME" -colorspace Gray "$TMP_IMAGE_NAME"
((OPERATION_CNT += 1))
}

AddBorder () {
local WIDTH=$(zenity --entry --title "Add Border" --text "Enter the border width:")
local COLOR=$(zenity --color-selection --title "Add Border" --show-palette)

while [[ "$(IsNumber "$WIDTH")" -eq 0 ]]; do
    local WIDTH=$(zenity --entry --title "Resize" --text "Enter the new width:")
done
convert "$TMP_IMAGE_NAME" -bordercolor "$COLOR" -border "${WIDTH}x${WIDTH}" "$TMP_IMAGE_NAME"
((OPERATION_CNT += 1))
}

ChangeBrightness () {
local VALUE=$(zenity --scale --title "Select new brightness" --text "Select new brightness:" \
--min-value=-100 --max-value=100 --step=1 --value=0 --width=400)

if [[ "$(IsNumber "$VALUE")" -eq 1 ]]; then
    convert "$TMP_IMAGE_NAME" -brightness-contrast "$VALUE"x0 "$TMP_IMAGE_NAME"
    ((OPERATION_CNT += 1))
else
    zenity --info --text="Cancelled operation"
fi
}

ChangeContrast () {
local VALUE=$(zenity --scale --title "Select new contrast" --text "Select new contrast:" \
--min-value=-100 --max-value=100 --step=1 --value=0 --width=400)

if [[ "$(IsNumber "$VALUE")" -eq 1 ]]; then
    convert "$TMP_IMAGE_NAME" -brightness-contrast 0x"$VALUE" "$TMP_IMAGE_NAME"
    ((OPERATION_CNT += 1))
else
    zenity --info --text="Cancelled operation"
fi
}

ChangeSaturation () {
local VALUE=$(zenity --scale --title "Select new saturation" --text "Select new saturation:" \
--min-value=0 --max-value=400 --step=1 --value=100 --width=400)

if [[ "$(IsNumber "$VALUE")" -eq 1 ]]; then
    convert "$TMP_IMAGE_NAME" -modulate 100,$VALUE "$TMP_IMAGE_NAME"
    ((OPERATION_CNT += 1))
else
    zenity --info --text="Cancelled operation"
fi
}

ManageWindow () {

while true
do
    # Display the menu
    CHOICE=$(zenity --list \
      --title "Image Editor" \
      --text "Select an option:" \
      --column "Option" --column "Description" \
      --width=550 --height=550 \
      1 "Rotate clockwise" \
      2 "Rotate counterclockwise" \
      3 "Flip horizontally" \
      4 "Flip vertically" \
      5 "Resize" \
      6 "Crop" \
      7 "Convert to grayscale" \
      8 "Add border" \
      9 "Change brightness" \
      10 "Change contrast" \
      11 "Change saturation" \
      12 "Exit")

# Handle the user's choice
    case $CHOICE in
      1) RotateClockwise ;;
      2) RotateCounterclockwise ;;
      3) FlipHorizontally ;;
      4) FlipVertically ;;
      5) ResizeImage ;;
      6) CropImage ;;
      7) GreyscaleImage ;;
      8) AddBorder ;;
      9) ChangeBrightness ;;
      10) ChangeContrast ;;
      11) ChangeSaturation ;;
      12) return ;;
      *) zenity --error --text "Invalid choice." ;;
    esac
done
}

#=======================PROGRAM_START==========================
OPERATION_CNT=0
#show_license
InstallImageMagick

# Prompt the user to select an image file using Zenity
ChooseImage
IMAGE_NAME=$(basename $IMAGE)
TMP_IMAGE_NAME="TMP_$IMAGE_NAME"
echo "Image name: "$IMAGE_NAME

cp $IMAGE $TMP_IMAGE_NAME

ManageWindow


echo "Changes done: "$OPERATION_CNT

if [ "$OPERATION_CNT" -gt 0 ]; then
    SAVE_DIR=$(zenity --file-selection --directory --title="Choose saving directory")
    case $? in
        0) mv "$TMP_IMAGE_NAME" "${SAVE_DIR}/edited_$IMAGE_NAME" ;;
        1) echo "Operation cancelled" | rm "$TMP_IMAGE_NAME" ;;
        -1) echo "Unexpected error occured" | rm "$TMP_IMAGE_NAME" ;;
    esac
else
    rm "$TMP_IMAGE_NAME"
fi

