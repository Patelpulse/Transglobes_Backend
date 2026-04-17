from pathlib import Path
import re


NGINX_FILE = Path("/etc/nginx/sites-available/transglobe-websites")


def inject_after_index(block: str, snippet: str) -> str:
    marker = "  index index.html;\n\n"
    if snippet.strip() in block:
        return block
    if marker in block:
        return block.replace(marker, marker + snippet, 1)
    return block


def main() -> None:
    text = NGINX_FILE.read_text()
    text = re.sub(
        r"  location \^~ /user/ \{\n\s*rewrite \^/user/\(\.\*\)\$ /\\1 break;\n\s*try_files \$uri \$uri/ /index\.html;\n\s*\}\n",
        "  location ^~ /user/ {\n    rewrite ^/user/?(.*)$ /$1 last;\n  }\n",
        text,
    )
    text = re.sub(
        r"  location \^~ /admin/ \{\n\s*rewrite \^/admin/\(\.\*\)\$ /\\1 break;\n\s*try_files \$uri \$uri/ /index\.html;\n\s*\}\n",
        "  location ^~ /admin/ {\n    rewrite ^/admin/?(.*)$ /$1 last;\n  }\n",
        text,
    )
    text = re.sub(
        r"  location \^~ /driver/ \{\n\s*rewrite \^/driver/\(\.\*\)\$ /\\1 break;\n\s*try_files \$uri \$uri/ /index\.html;\n\s*\}\n",
        "  location ^~ /driver/ {\n    rewrite ^/driver/?(.*)$ /$1 last;\n  }\n",
        text,
    )
    text = re.sub(
        r"  location \^~ /corporate/ \{\n\s*rewrite \^/corporate/\(\.\*\)\$ /\\1 break;\n\s*try_files \$uri \$uri/ /index\.html;\n\s*\}\n",
        "  location ^~ /corporate/ {\n    rewrite ^/corporate/?(.*)$ /$1 last;\n  }\n",
        text,
    )
    original = text

    parts = text.split("server {")
    output = [parts[0]]

    for part in parts[1:]:
        block = "server {" + part

        if (
            "server_name transgloble.com www.transgloble.com;" in block
            and "root /var/www/transglobe-sites/root;" in block
        ):
            snippet = (
                "  location ^~ /user/ {\n"
                "    rewrite ^/user/?(.*)$ /$1 last;\n"
                "  }\n\n"
            )
            block = inject_after_index(block, snippet)

        if (
            "server_name admin.transgloble.com;" in block
            and "root /var/www/transglobe-sites/admin;" in block
        ):
            snippet = (
                "  location ^~ /admin/ {\n"
                "    rewrite ^/admin/?(.*)$ /$1 last;\n"
                "  }\n\n"
            )
            block = inject_after_index(block, snippet)

        if (
            "server_name driver.transgloble.com;" in block
            and "root /var/www/transglobe-sites/driver;" in block
        ):
            snippet = (
                "  location ^~ /driver/ {\n"
                "    rewrite ^/driver/?(.*)$ /$1 last;\n"
                "  }\n\n"
            )
            block = inject_after_index(block, snippet)

        if (
            "server_name corporate.transgloble.com;" in block
            and "root /var/www/transglobe-sites/corporate;" in block
        ):
            snippet = (
                "  location ^~ /corporate/ {\n"
                "    rewrite ^/corporate/?(.*)$ /$1 last;\n"
                "  }\n\n"
            )
            block = inject_after_index(block, snippet)

        output.append(block)

    updated = "".join(output)
    if updated != original:
        NGINX_FILE.write_text(updated)
        print("updated")
    else:
        print("nochange")


if __name__ == "__main__":
    main()
