#!/bin/bash

# Check if username is passed as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

glnk_username="$1"
glnk_html=build/index.html

# Create the build directory if it doesn't exist
mkdir -p build

# Create the HTML file using the JSON data
cat <<EOL >$glnk_html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Go Link to Your URL - glnk.dev">
    <meta property="og:title" content="Go Links - $glnk_username.glnk.dev">
    <meta property="og:description" content="Easily manage your custom short links with glnk.dev.">
    <meta property="og:image" content="https://raw.githubusercontent.com/glnk-dev/.github/main/favicon.png">
    <meta property="og:url" content="https://$glnk_username.glnk.dev">
    <title>Go Links - $glnk_username.glnk.dev</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <link rel="icon" href="https://raw.githubusercontent.com/glnk-dev/.github/main/favicon.ico" type="image/x-icon">
</head>
<body class="bg-gray-100 text-gray-900">
    <div class="container mx-auto p-4">
        <header class="mb-8">
            <h1 class="text-3xl font-bold">Go Links - $glnk_username.glnk.dev</h1>
            <p class="mt-2 text-lg">Easily manage your custom short links with <a href="https://glnk.dev" class="text-blue-500 hover:underline">glnk.dev</a>.</p>
        </header>
        <table class="min-w-full bg-white shadow-md rounded-lg">
            <thead>
                <tr>
                    <th class="py-2 px-4 bg-gray-200 font-semibold text-gray-700">Subpath</th>
                    <th class="py-2 px-4 bg-gray-200 font-semibold text-gray-700">Redirect Link</th>
                </tr>
            </thead>
            <tbody>
EOL

# Loop through the JSON data and generate the table rows
jq -r '. | to_entries[] | "<tr><td class=\"border-t py-2 px-4\"><a href=\"" + .key + "\" class=\"text-blue-500 hover:underline\">" + .key + "</a></td><td class=\"border-t py-2 px-4\"><a href=\"" + .value + "\" class=\"text-blue-500 hover:underline\">" + .value + "</a></td></tr>"' glnk.json >>$glnk_html

# Complete the HTML file
cat <<EOL >>$glnk_html
            </tbody>
        </table>
    </div>
</body>
</html>
EOL

echo "Generated $glnk_html successfully!"

declare -A redirect_mapping

# Assuming glnk.json contains a valid JSON object with keys and values.
# For example:
# {
#   "subpath1": "redirect_link1",
#   "subpath2": "redirect_link2",
#   ...
# }

# Read the JSON file and populate the associative array
while read -r subpath redirect_link; do
    redirect_mapping["$subpath"]=$redirect_link
done < <(jq -r 'to_entries[] | "\(.key) \(.value)"' glnk.json)

# Iterate through the associative array to get the matching order
for subpath in "${!redirect_mapping[@]}"; do
    redirect_link="${redirect_mapping[$subpath]}"
    echo "Subpath: $subpath, Redirect Link: $redirect_link"

    # Create the content for the index.html file
    content="<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Redirecting to $redirect_link</title>
    <link rel=\"canonical\" href=\"$redirect_link\">
    <link rel=\"icon\" href=\"https://glnk.dev/favicon.ico\" type=\"image/x-icon\">
    <meta http-equiv=\"refresh\" content=\"0; URL=$redirect_link\">
    <meta property=\"og:title\" content=\"$subpath - $glnk_username.glnk.dev\">
    <meta property=\"og:description\" content=\"Redirecting to $redirect_link\">
    <meta property=\"og:image\" content=\"https://raw.githubusercontent.com/glnk-dev/.github/main/favicon.png\">
    <meta property=\"og:url\" content=\"https://$glnk_username.glnk.dev$subpath\">
</head>
<body>
    <p>If you are not redirected, <a href=\"$redirect_link\">click here</a>.</p>
</body>
</html>
"

    # Create the directory for the subpath if it doesn't exist
    mkdir -p "build$subpath"

    # Write the content to the index.html file
    echo "$content" >"build$subpath/index.html"
done

echo "Created subdirectories with index.html files successfully!"
