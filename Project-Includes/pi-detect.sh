
function pi-detect()
{
print_info Now running "$FUNCNAME"....
if [ -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="1"
fi

if [ ! -f /sys/firmware/devicetree/base/model ] ; then
export IS_RASPI="0"
fi
print_info Completed running "$FUNCNAME"
}