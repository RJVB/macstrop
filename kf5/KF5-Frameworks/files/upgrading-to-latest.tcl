# if {(${kf5.latest_version} ne ${kf5.version}) && [file exists ${filespath}/enable_latest]} {
#     kf5.use_latest  kf5.version
#     version         ${kf5.version}
#     set checksums.table \
#                     checksums-${kf5.version}.table
# } else {
#     set checksums.table \
#                     checksums.table
# }

# # a convenience procedure that allows non-dev users to build the
# # previous version which still requires a specific patch that has become
# # obsolete in the new version to which all subports are being upgraded.
# proc versioned_patchfile_append {d f} {
#     global filespath version
#     if {[file exists ${filespath}/${d}/${version}/${f}]} {
#         patchfiles-append \
#                     ${d}/${version}/${f}
#     }
# }
