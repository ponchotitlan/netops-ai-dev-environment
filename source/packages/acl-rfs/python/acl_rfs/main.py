# -*- mode: python; python-indent: 4 -*-
"""ACL RFS service: configures named IPv4 access lists on IOS XR devices."""

from typing import Any, Optional

import ncs
from ncs.application import Service


class AccessListService(Service):
    """Service callbacks for the access-list-acl-rfs-servicepoint servicepoint."""

    @Service.create
    def cb_create(
        self,
        tctx: Any,
        root: ncs.maagic.Root,
        service: ncs.maagic.ListElement,
        proplist: list[tuple[str, str]],
    ) -> Optional[list[tuple[str, str]]]:
        """Apply the access_list template for every rule of every access list in the service.

        Args:
            tctx: Transaction context of the service invocation.
            root: Root node of the transaction.
            service: The service instance being created or modified.
            proplist: Opaque properties kept between FASTMAP invocations.

        Returns:
            None, as no properties are stored.
        """
        self.log.info("Service create(service=", service._path, ")")
        template = ncs.template.Template(service)
        tvars = ncs.template.Variables()
        tvars.add("DEVICE", service.device)
        for access_list in service.access_list:
            tvars.add("NAME", access_list.name)
            for rule in access_list.rule:
                tvars.add("RULE_ID", rule.id)
                tvars.add("ACTION", rule.action)
                tvars.add("DESTINATION", rule.destination)
                template.apply("access_list", tvars)
        return None


class Main(ncs.application.Application):
    """NSO application component that registers the ACL RFS service."""

    def setup(self) -> None:
        """Register the service callbacks with NSO."""
        self.log.info("Main RUNNING")
        self.register_service("access-list-acl-rfs-servicepoint", AccessListService)

    def teardown(self) -> None:
        """Log that the application is stopping."""
        self.log.info("Main FINISHED")
