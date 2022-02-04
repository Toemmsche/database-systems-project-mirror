import { ComponentFixture, TestBed } from '@angular/core/testing';

import { BundeslandComponent } from './bundesland.component';

describe('BundeslaenderComponent', () => {
  let component: BundeslandComponent;
  let fixture: ComponentFixture<BundeslandComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [BundeslandComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(BundeslandComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
