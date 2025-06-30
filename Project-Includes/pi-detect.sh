
function pi-detect()
{
echo Now running "$FUNCNAME"....
if [ -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="1"
fi

if [ ! -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="0"
fi
echo Completed running "$FUNCNAME"
}