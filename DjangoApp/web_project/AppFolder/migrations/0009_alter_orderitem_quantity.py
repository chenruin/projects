# Generated by Django 4.2.6 on 2023-12-10 03:23

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("AppFolder", "0008_rename_item_order_items"),
    ]

    operations = [
        migrations.AlterField(
            model_name="orderitem",
            name="quantity",
            field=models.IntegerField(default=0),
        ),
    ]
