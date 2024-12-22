from django.shortcuts import HttpResponse, render
from datetime import datetime as dt
from visits.models import PageVisit


def home(req):
    return HttpResponse("Home page")


def visits(req):
    query_set = PageVisit.objects
    query_set.create(path=req.path)
    context = {
        "page_visit_count": query_set.all().count(),
        "page_visit_timestamp": query_set.values("timestamp")[-1]["timestamp"],
    }
    return render(req, "visits/visits.html", context)
