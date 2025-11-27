#!/bin/bash
users=(
    "admin" "finance" "hr" "it_support" "ceo" "cto"
    "sales_mgr" "marketing" "devops" "legal" "intern_john" "intern_jane"
)

for u in "${users[@]}"
do
    useradd -m "$u" 2>/dev/null
    echo "$u:Password123" | chpasswd
done

echo "organization-style users created"