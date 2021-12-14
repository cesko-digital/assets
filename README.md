# Česko.Digital Assets

Synchronizační repozitář pro soubory hostované na [data.cesko.digital](https://data.cesko.digital).

## Přidání nového obsahu

Pro přidání nového souboru na [data.cesko.digital](https://data.cesko.digital) je nutné:

1. Soubor nahrát do složky `content`(například pro obrázek na blog, jdi do složky "img" a dej "add a file" a "Upload files")
2. Do "Commit changes" napiš název obrázku a dej "Commit changes"
4. Vytvořit pull request a provést kontrolu pomocí přidání jednoho z reviwers Karmi, Zoul, Martin Wenish (pull request by měl obsahovat změny pouze ve složce `content`, viz sekce _Změna infrastruktury_)
5. Merge

Cesta k souboru kopíruje strukturu repozitáře, tedy soubor `content/prirucka.pdf` bude k dispozici na adrese `data.cesko.digital/prirucka.pdf`.

## Přístup k náhledům obrázků

Distribuce na [data.cesko.digital](https://data.cesko.digital) umožňuje vracet obrázky s jinou požadovanou šířkou.
Stačí zavolat URL [https://data.cesko.digital/resize](https://data.cesko.digital/resize). 

Funkce má následující query parametry:

- `src` **povinný parametr -** relativní adresa k obrázku (origin je natvrdo nastaven na [data.cesko.digital](https://data.cesko.digital))
- `width` **povinný parametr -** požadovaná výsledná šířka obrázku (poměr stran je zachován)

Příklad výsledného volání: `https://data.cesko.digital/resize?src=/img/show-and-tell-1.png&width=500`

## Automatizovaná data

Součástí definice infrastruktury je i bucket pro automatizovaná data jako je např. [derisking-handbook](https://github.com/cesko-digital/derisking-handbook).

Nahrávání do tohoto bucketu je řešeno odděleně, ale požadavek je přesměrován na tento "automatizovaný bucket" pokud soubor není nalezen v primárním bucketu.  

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

## Kontakty

**Tech leads:** [Tomáš Znamenáček](https://github.com/zoul), [Martin Wenisch](https://github.com/martinwenisch)
