add-content -path c:/users/abhunia/.ssh/config -value @'

Host {hostname}
  HostName {hostname}
  User {user}
  IdentityFile {identityfile}
'@