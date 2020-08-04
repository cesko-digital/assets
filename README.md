# Česko.Digital Assets

Synchronizační repozitář pro soubory hostované na [data.cesko.digital](https://data.cesko.digital).

## Přidání nového obsahu

Pro přidání nového souboru na [data.cesko.digital](https://data.cesko.digital) je nutné:

1. Soubor nahrát do složky `content`
2. Vytvořit krátkodobou větev a commit se souborem
3. Push
4. Vytvořit pull request a provést kontrolu (pull request by měl obsahovat změny pouze ve složce `content`, viz sekce _Změna infrastruktury_)
5. Merge

Cesta k souboru kopíruje strukturu repozitáře, tedy soubor `content/prirucka.pdf` bude k dispozici na adrese `data.cesko.digital/prirucka.pdf`. 

## Setup nové instance

Pro nastavení AWS S3 a Cloudfront lze využít Terraform konfiguraci. 

Nejprve je nutné spustit lokálně `terraform apply` pro tuto část: 

```hcl-terraform
provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "infrastructure_bucket" {
  bucket = "cd-assets-infrastructure"
  acl    = "private"
}
```

Potom spustit `terraform init` pro přidanou část: 

```hcl-terraform
terraform {
  backend "s3" {
    bucket = "cd-assets-infrastructure"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

```

Pak už stačí nastavit tyto GitHub secrets a zbylá infrastruktura bude nasazena pomocí GitHub Action:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DISTRIBUTION_ID` (Bude vygenerováno pomocí Terraform)
- `DOMAIN`
- `SSL_CERTIFICATE_ARN` (Nutné vygenerovat pomocí AWS Certificate Manager)

## Změna infrastruktury

Veškeré změny infrastruktury by měly probíhat odděleně od změn obsahu. Tedy nejprve vytvořit pull request se změnou konfigurace infrastruktury, počkat na aplikování a poté vytvořit nový pull request pro obsah.

## Licence

Konfigurace AWS a zdroje pro synchronizaci jsou zveřejněny pod [licencí MIT](https://github.com/cesko-digital/assets/blob/master/LICENSE). Na obsah ve složce `content` se může vztahovat jiná licence.   

